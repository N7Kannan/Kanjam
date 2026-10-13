import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../models/account.dart';
import '../../services/account_service.dart';
import '../../services/auth_service.dart';
import '../../services/budget_service.dart';
import '../../services/finance_calculator.dart';
import '../../services/goal_service.dart';
import '../../services/notification_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/budget_card.dart';
import '../../widgets/common.dart';
import '../../widgets/goal_card.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_tile.dart';
import '../budget/monthly_budget_screen.dart';
import '../credit/credit_screen.dart';
import '../debit/debit_screen.dart';
import '../notifications/notifications_screen.dart';
import '../transactions/transaction_details.dart';
import 'connect_account_sheet.dart';

/// Dashboard. Every figure is calculated from the stored accounts and
/// transactions each time they change; nothing here is a fixed number.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onSelectTab});

  /// Switches the bottom-navigation tab (1 = Transactions, 2 = Reports, 3 = Goals).
  final ValueChanged<int> onSelectTab;

  void _push(BuildContext context, Widget screen) {
    pushOnce<void>(context, screen);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final user = context.watch<AuthService>().user;
    final accounts = context.watch<AccountService>().accounts;
    final txs = context.watch<TransactionService>().all;
    final budgets = context.watch<BudgetService>().budgets;
    final goals = context.watch<GoalService>().goals;
    final unread = context.watch<NotificationService>().unreadCount;
    final now = DateTime.now();

    final balances = FinanceCalculator.balances(accounts, txs);
    double sumOf(AccountType type) {
      var sum = 0.0;
      for (final a in accounts) {
        if (a.type == type) sum += balances[a.id] ?? 0;
      }
      return round2(sum);
    }

    final cash = sumOf(AccountType.cash);
    final bank = sumOf(AccountType.bank);
    final invested = sumOf(AccountType.investment);
    final total = round2(cash + bank + invested);

    final month = FinanceCalculator.summarize(FinanceCalculator.inMonth(txs, now));
    final statuses = FinanceCalculator.budgetStatuses(budgets, txs, now)
      ..sort((a, b) => b.ratio.compareTo(a.ratio));
    final openGoals = List.of(goals)
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return b.progress.compareTo(a.progress);
      });
    final plannedIncome = user?.monthlyIncome ?? 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(Fmt.greeting(), style: TextStyle(color: p.textSecondary)),
                      Text(
                        user?.firstName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => _push(context, const NotificationsScreen()),
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text(unread > 99 ? '99+' : '$unread'),
                    child: Icon(Icons.notifications_outlined, color: p.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BalanceCard(total: total, cash: cash, bank: bank, investment: invested),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: SummaryCard(
                    label: 'Income',
                    amount: month.income,
                    icon: Icons.south_west,
                    color: p.credit,
                    caption: plannedIncome > 0
                        ? 'This month - of ${Fmt.money(plannedIncome, decimals: false)} planned'
                        : 'This month',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    label: 'Expense',
                    amount: month.expense,
                    icon: Icons.north_east,
                    color: p.debit,
                    caption: 'This month',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                const columns = 4;
                const spacing = 8.0;
                final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                final actions = <Widget>[
                  _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Add Credit',
                    color: p.credit,
                    onTap: () => _push(context, const CreditScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.remove_circle_outline,
                    label: 'Add Debit',
                    color: p.debit,
                    onTap: () => _push(context, const DebitScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.pie_chart_outline,
                    label: 'Budget',
                    color: p.warning,
                    onTap: () => _push(context, const MonthlyBudgetScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.flag_outlined,
                    label: 'Goals',
                    color: p.accent,
                    onTap: () => onSelectTab(3),
                  ),
                  _QuickAction(
                    icon: Icons.bar_chart,
                    label: 'Reports',
                    color: p.accent,
                    onTap: () => onSelectTab(2),
                  ),
                  _QuickAction(
                    icon: Icons.account_balance_outlined,
                    label: 'Connect Account',
                    color: p.accent,
                    onTap: () => showAccountSheet(context),
                  ),
                ];
                return Wrap(
                  spacing: spacing,
                  runSpacing: 14,
                  children: actions.map((a) => SizedBox(width: width, child: a)).toList(),
                );
              },
            ),
            const SizedBox(height: 26),
            SectionHeader(
              title: 'Accounts',
              actionLabel: 'Connect Account',
              onAction: () => showAccountSheet(context),
            ),
            const SizedBox(height: 8),
            if (accounts.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No accounts yet',
                  message: 'Add your cash wallet, bank or investments to start tracking.',
                  actionLabel: 'Connect Account',
                  onAction: () => showAccountSheet(context),
                ),
              )
            else
              ...accounts.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AccountTile(
                    account: a,
                    balance: balances[a.id] ?? 0,
                    onTap: () => showAccountSheet(context, existing: a),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Monthly Budget',
              actionLabel: 'Manage',
              onAction: () => _push(context, const MonthlyBudgetScreen()),
            ),
            const SizedBox(height: 8),
            if (statuses.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.pie_chart_outline,
                  title: 'No budgets configured yet',
                  message: 'Set a monthly limit and KANJAM will warn you at 80% and 100%.',
                  actionLabel: 'Set Monthly Budgets',
                  onAction: () => _push(context, const MonthlyBudgetScreen()),
                ),
              )
            else
              ...statuses.take(3).map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BudgetCard(
                        status: s,
                        onTap: () => _push(context, const MonthlyBudgetScreen()),
                      ),
                    ),
                  ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Goals & Savings',
              actionLabel: 'See all',
              onAction: () => onSelectTab(3),
            ),
            const SizedBox(height: 8),
            if (openGoals.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.flag_outlined,
                  title: 'No financial goals yet',
                  message: 'Save towards a laptop, a trip or an emergency fund.',
                  actionLabel: 'Set Your First Goal',
                  onAction: () => onSelectTab(3),
                ),
              )
            else
              ...openGoals.take(2).map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GoalCard(goal: g, compact: true),
                    ),
                  ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Recent Transactions',
              actionLabel: 'See all',
              onAction: () => onSelectTab(1),
            ),
            const SizedBox(height: 4),
            if (txs.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions recorded yet.',
                  message: 'Add a credit or an expense and your balance updates instantly.',
                  actionLabel: 'Add Expense',
                  onAction: () => _push(context, const DebitScreen()),
                ),
              )
            else
              ...txs.take(5).map(
                    (t) => Column(
                      children: <Widget>[
                        TransactionTile(
                          transaction: t,
                          accountName:
                              context.read<AccountService>().byId(t.accountId)?.name ??
                                  'Deleted account',
                          onTap: () => showTransactionDetails(context, t),
                        ),
                        Divider(height: 1, color: p.border),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.textSecondary, fontSize: 12, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account, required this.balance, required this.onTap});

  final AccountModel account;
  final double balance;
  final VoidCallback onTap;

  IconData get _icon {
    switch (account.type) {
      case AccountType.cash:
        return Icons.payments_outlined;
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.investment:
        return Icons.trending_up;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final last4 = account.last4;
    final subtitle = <String>[
      account.type.label,
      if (last4 != null) '\u2022\u2022\u2022\u2022 $last4',
    ].join(' \u2022 ');
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 20, color: p.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
                ),
                Text(subtitle, style: TextStyle(color: p.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                Fmt.money(balance),
                style: TextStyle(
                  color: balance < 0 ? p.debit : p.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
