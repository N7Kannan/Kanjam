import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/categories.dart';
import '../core/constants.dart';
import '../core/formatters.dart';
import '../core/ids.dart';
import '../core/money.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/notification_item.dart';
import '../models/transaction.dart';
import 'account_service.dart';
import 'auth_service.dart';
import 'budget_service.dart';
import 'finance_calculator.dart';
import 'goal_service.dart';
import 'notification_service.dart';
import 'transaction_service.dart';

/// Operations that touch more than one service (a transaction also raises
/// budget alerts, onboarding creates accounts, and so on). Screens call this
/// instead of juggling several services, so the rules live in one place.
class FinanceCoordinator {
  FinanceCoordinator({
    required this.auth,
    required this.accounts,
    required this.transactions,
    required this.budgets,
    required this.goals,
    required this.notifications,
  }) {
    // Registered before any widget listens, so data is already loaded for the
    // new user by the time the UI rebuilds after a login or logout.
    auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final AuthService auth;
  final AccountService accounts;
  final TransactionService transactions;
  final BudgetService budgets;
  final GoalService goals;
  final NotificationService notifications;

  String? _loadedFor;
  bool _firstLoad = true;

  void _onAuthChanged() {
    final uid = auth.user?.id;
    if (!_firstLoad && uid == _loadedFor) return;
    _firstLoad = false;
    _loadedFor = uid;
    accounts.loadForUser(uid);
    transactions.loadForUser(uid);
    budgets.loadForUser(uid);
    goals.loadForUser(uid);
    notifications.loadForUser(uid);
  }

  bool get _alertsOn => auth.user?.notificationsEnabled ?? false;

  // ---- transactions -------------------------------------------------------

  /// Saves a new or edited transaction. Returns an error message, or null.
  Future<String?> saveTransaction(TransactionModel tx, {required bool isEdit}) async {
    if (!tx.amount.isFinite || tx.amount <= 0) return 'Amount must be greater than 0';
    if (!AmountParser.isWithinLimit(tx.amount)) return 'Amount is too large';
    final account = accounts.byId(tx.accountId);
    if (account == null) return 'Choose an account for this transaction';
    try {
      if (isEdit) {
        await transactions.update(tx);
      } else {
        await transactions.add(tx);
      }
    } catch (e) {
      debugPrint('KANJAM: saveTransaction failed: $e');
      return 'Could not save the transaction. Please try again.';
    }
    await _afterTransaction(tx, account, isNew: !isEdit);
    return null;
  }

  Future<void> deleteTransaction(String id) => transactions.remove(id);

  Future<void> _afterTransaction(
    TransactionModel tx,
    AccountModel account, {
    required bool isNew,
  }) async {
    // The transaction is already saved; a failure here must not undo it.
    try {
      if (!_alertsOn) return;
      if (isNew) {
        await notifications.addIfAbsent(NotificationItem(
          id: 'notif_tx_${tx.id}',
          userId: tx.userId,
          title: tx.isCredit ? 'Credit Added' : 'Debit Added',
          message: tx.isCredit
              ? '${Fmt.money(tx.amount)} credited to ${account.name}'
              : '${Fmt.money(tx.amount)} debited for ${tx.category}',
          kind: NotificationKind.transaction,
          createdAt: DateTime.now(),
        ));
      }
      if (tx.isDebit) await evaluateBudgetAlerts(tx.date);
    } catch (e) {
      debugPrint('KANJAM: post-transaction alerts failed: $e');
    }
  }

  // ---- budgets ------------------------------------------------------------

  Future<String?> saveBudget(BudgetModel budget, {required bool isNew}) async {
    if (isNew) {
      final error = await budgets.add(budget);
      if (error != null) return error;
    } else {
      await budgets.update(budget);
    }
    try {
      await evaluateBudgetAlerts(DateTime.now());
    } catch (e) {
      debugPrint('KANJAM: budget alert check failed: $e');
    }
    return null;
  }

  /// Raises an 80% or 100% alert for each budget in [month], once per
  /// budget/month/level (the notification id makes repeats impossible).
  Future<void> evaluateBudgetAlerts(DateTime month) async {
    if (!_alertsOn) return;
    final uid = auth.user?.id;
    if (uid == null) return;
    final key = FinanceCalculator.monthKey(month);
    final isCurrent = FinanceCalculator.sameMonth(month, DateTime.now());
    final when = isCurrent ? 'this month' : 'in ${Fmt.monthYear(month)}';

    for (final b in budgets.budgets) {
      final s = FinanceCalculator.budgetStatus(b, transactions.all, month);
      final name = b.category == Categories.overall ? 'overall' : b.category;
      if (s.ratio >= 1) {
        await notifications.addIfAbsent(NotificationItem(
          id: 'notif_bg_100_${b.id}_$key',
          userId: uid,
          title: s.exceeded ? 'Budget Exceeded!' : 'Budget Limit Reached',
          message: s.exceeded
              ? 'You have exceeded your $name budget $when by ${Fmt.money(-s.remaining)}.'
              : 'You have used 100% of your $name budget $when.',
          kind: NotificationKind.budget,
          createdAt: DateTime.now(),
        ));
      } else if (s.ratio >= AppConstants.budgetWarnRatio) {
        await notifications.addIfAbsent(NotificationItem(
          id: 'notif_bg_80_${b.id}_$key',
          userId: uid,
          title: '80% Budget Alert',
          message: 'You have used ${Fmt.percent(s.ratio)} of your $name budget $when. '
              '${Fmt.money(s.remaining)} left.',
          kind: NotificationKind.budget,
          createdAt: DateTime.now(),
        ));
      }
    }
  }

  // ---- goals --------------------------------------------------------------

  Future<String?> saveGoal(GoalModel goal, {required bool isNew}) async {
    final previous = isNew ? null : goals.byId(goal.id);
    final error = isNew ? await goals.add(goal) : await goals.update(goal);
    if (error != null) return error;
    if (goal.isCompleted && !(previous?.isCompleted ?? false)) {
      await _notifyGoalReached(goal);
    }
    return null;
  }

  Future<void> addMoneyToGoal(GoalModel goal, double amount) async {
    final updated = goal.copyWith(currentAmount: round2(goal.currentAmount + amount));
    await goals.update(updated);
    if (!_alertsOn) return;
    try {
      if (updated.isCompleted && !goal.isCompleted) {
        await _notifyGoalReached(updated);
      } else {
        await notifications.addIfAbsent(NotificationItem(
          id: IdGen.next('notif_goal_add'),
          userId: updated.userId,
          title: 'Goal Update',
          message: 'You added ${Fmt.money(amount)} to "${updated.name}". '
              '${Fmt.percent(updated.progress)} of ${Fmt.money(updated.targetAmount)} saved.',
          kind: NotificationKind.goal,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('KANJAM: goal notification failed: $e');
    }
  }

  Future<void> _notifyGoalReached(GoalModel goal) async {
    if (!_alertsOn) return;
    try {
      await notifications.addIfAbsent(NotificationItem(
        id: 'notif_goal_${goal.id}',
        userId: goal.userId,
        title: 'Goal Update',
        message: 'Congratulations! You have reached your goal for "${goal.name}".',
        kind: NotificationKind.goal,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('KANJAM: goal notification failed: $e');
    }
  }

  // ---- accounts -----------------------------------------------------------

  /// Deletes an account only when nothing references it.
  Future<String?> deleteAccount(String id) async {
    final count = transactions.countForAccount(id);
    if (count > 0) {
      return 'This account has $count transaction${count == 1 ? '' : 's'}. '
          'Delete or move them first.';
    }
    await accounts.remove(id);
    return null;
  }

  // ---- onboarding / reset -------------------------------------------------

  static double _number(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  /// Turns the saved onboarding answers into real accounts, then marks
  /// onboarding done. Safe to run twice (account ids are fixed per user).
  Future<void> completeOnboarding() async {
    final u = auth.user;
    if (u == null) return;
    final d = u.onboardingDraft;
    final now = DateTime.now();

    final list = <AccountModel>[
      AccountModel(
        id: 'acc_cash_${u.id}',
        userId: u.id,
        name: 'Main Cash Wallet',
        type: AccountType.cash,
        openingBalance: round2(_number(d['cash'])),
        createdAt: now,
      ),
    ];
    if (d['bankAdded'] == true) {
      final provider = (d['bankProvider'] as String?)?.trim();
      list.add(AccountModel(
        id: 'acc_bank_${u.id}',
        userId: u.id,
        name: (provider == null || provider.isEmpty) ? 'Bank Account' : provider,
        type: AccountType.bank,
        provider: provider,
        openingBalance: round2(_number(d['bankBalance'])),
        createdAt: now.add(const Duration(milliseconds: 1)),
      ));
    }
    if (d['investAdded'] == true) {
      final kind = (d['investType'] as String?)?.trim();
      list.add(AccountModel(
        id: 'acc_inv_${u.id}',
        userId: u.id,
        name: (kind == null || kind.isEmpty) ? 'Investments' : kind,
        type: AccountType.investment,
        provider: kind,
        openingBalance: round2(_number(d['investBalance'])),
        createdAt: now.add(const Duration(milliseconds: 2)),
      ));
    }
    await accounts.upsertAll(list);
    await auth.markOnboardingComplete();
  }

  /// Clears transactions, budgets, goals and notifications. Accounts and their
  /// opening balances are kept.
  Future<void> eraseUserData() async {
    final uid = auth.user?.id;
    if (uid == null) return;
    await transactions.removeAllForUser(uid);
    await budgets.removeAllForUser(uid);
    await goals.removeAllForUser(uid);
    await notifications.clearAll();
  }
}
