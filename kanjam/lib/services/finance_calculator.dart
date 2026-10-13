import '../core/categories.dart';
import '../core/constants.dart';
import '../core/money.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/transaction.dart';

/// Income, expense and net for a set of transactions.
class MonthSummary {
  const MonthSummary({required this.income, required this.expense});

  final double income;
  final double expense;

  double get net => round2(income - expense);

  /// Net / income, or null when there is no income to compare against.
  double? get savingsRate => income > 0 ? net / income : null;
}

class CategoryTotal {
  const CategoryTotal(this.category, this.amount, this.share);

  final String category;
  final double amount;

  /// 0.0 - 1.0 share of all expenses in the period.
  final double share;
}

enum BudgetLevel { ok, warning, reached, exceeded }

class BudgetStatus {
  const BudgetStatus({required this.budget, required this.spent});

  final BudgetModel budget;
  final double spent;

  double get limit => budget.monthlyLimit;
  double get remaining => round2(limit - spent);
  double get ratio => limit > 0 ? spent / limit : 0;

  /// 0.0 - 1.0 for progress bars.
  double get barValue {
    final r = ratio;
    if (r.isNaN || r < 0) return 0;
    return r > 1 ? 1 : r;
  }

  BudgetLevel get level {
    if (spent > limit) return BudgetLevel.exceeded;
    if (spent >= limit) return BudgetLevel.reached;
    if (ratio >= AppConstants.budgetWarnRatio) return BudgetLevel.warning;
    return BudgetLevel.ok;
  }

  bool get exceeded => level == BudgetLevel.exceeded;
}

/// All money maths lives here as pure functions so it can be unit tested and
/// every screen shows the same numbers.
class FinanceCalculator {
  FinanceCalculator._();

  static DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

  /// Month arithmetic that rolls over years correctly (Dec + 1 = Jan).
  static DateTime addMonths(DateTime d, int months) => DateTime(d.year, d.month + months);

  static bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  static String monthKey(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}';

  static List<TransactionModel> inMonth(Iterable<TransactionModel> tx, DateTime month) =>
      tx.where((t) => sameMonth(t.date, month)).toList();

  static MonthSummary summarize(Iterable<TransactionModel> tx) {
    var income = 0.0;
    var expense = 0.0;
    for (final t in tx) {
      if (t.isCredit) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return MonthSummary(income: round2(income), expense: round2(expense));
  }

  /// Current balance per account id: opening balance + credits - debits.
  static Map<String, double> balances(
    List<AccountModel> accounts,
    Iterable<TransactionModel> tx,
  ) {
    final out = <String, double>{for (final a in accounts) a.id: a.openingBalance};
    for (final t in tx) {
      final current = out[t.accountId];
      if (current != null) out[t.accountId] = current + t.signedAmount;
    }
    return out.map<String, double>((k, v) => MapEntry<String, double>(k, round2(v)));
  }

  static double totalBalance(List<AccountModel> accounts, Iterable<TransactionModel> tx) {
    final b = balances(accounts, tx);
    return round2(b.values.fold<double>(0, (sum, v) => sum + v));
  }

  static double balanceOfType(
    List<AccountModel> accounts,
    Iterable<TransactionModel> tx,
    AccountType type,
  ) {
    final b = balances(accounts, tx);
    var sum = 0.0;
    for (final a in accounts) {
      if (a.type == type) sum += b[a.id] ?? 0;
    }
    return round2(sum);
  }

  /// Expense totals per category, largest first.
  static List<CategoryTotal> expenseByCategory(Iterable<TransactionModel> tx) {
    final totals = <String, double>{};
    for (final t in tx) {
      if (t.isDebit) totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final sum = totals.values.fold<double>(0, (a, b) => a + b);
    final list = totals.entries
        .map((e) => CategoryTotal(e.key, round2(e.value), sum > 0 ? e.value / sum : 0))
        .toList();
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  /// Expense per week of [month]: days 1-7, 8-14, 15-21 and 22-end.
  static List<double> weeklyExpense(Iterable<TransactionModel> tx, DateTime month) {
    final weeks = List<double>.filled(4, 0);
    for (final t in tx) {
      if (t.isDebit && sameMonth(t.date, month)) {
        var index = (t.date.day - 1) ~/ 7;
        if (index > 3) index = 3;
        weeks[index] += t.amount;
      }
    }
    return weeks.map(round2).toList();
  }

  static double spentForBudget(BudgetModel b, Iterable<TransactionModel> tx, DateTime month) {
    var spent = 0.0;
    for (final t in tx) {
      if (!t.isDebit || !sameMonth(t.date, month)) continue;
      if (b.category == Categories.overall || t.category == b.category) spent += t.amount;
    }
    return round2(spent);
  }

  static BudgetStatus budgetStatus(BudgetModel b, Iterable<TransactionModel> tx, DateTime month) =>
      BudgetStatus(budget: b, spent: spentForBudget(b, tx, month));

  static List<BudgetStatus> budgetStatuses(
    List<BudgetModel> budgets,
    Iterable<TransactionModel> tx,
    DateTime month,
  ) =>
      budgets.map((b) => budgetStatus(b, tx, month)).toList();
}
