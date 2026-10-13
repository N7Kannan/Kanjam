import 'package:flutter_test/flutter_test.dart';
import 'package:kanjam/models/account.dart';
import 'package:kanjam/models/budget.dart';
import 'package:kanjam/models/transaction.dart';
import 'package:kanjam/services/finance_calculator.dart';

TransactionModel tx({
  required String id,
  required bool credit,
  required double amount,
  required DateTime date,
  String category = 'Food',
  String account = 'a1',
}) {
  return TransactionModel(
    id: id,
    userId: 'u',
    isCredit: credit,
    amount: amount,
    category: category,
    accountId: account,
    mode: 'UPI',
    date: date,
    createdAt: date,
  );
}

AccountModel account(String id, AccountType type, double opening) => AccountModel(
      id: id,
      userId: 'u',
      name: id,
      type: type,
      openingBalance: opening,
      createdAt: DateTime(2026),
    );

BudgetModel budget(String category, double limit) => BudgetModel(
      id: 'b_$category',
      userId: 'u',
      category: category,
      monthlyLimit: limit,
      createdAt: DateTime(2026),
    );

void main() {
  final cash = account('a1', AccountType.cash, 1000);
  final bank = account('a2', AccountType.bank, 5000);
  final oct = DateTime(2026, 10, 15);
  final sep = DateTime(2026, 9, 15);

  group('balances', () {
    test('with no transactions the balance is the opening balance', () {
      expect(FinanceCalculator.balances([cash, bank], const []), {'a1': 1000.0, 'a2': 5000.0});
      expect(FinanceCalculator.totalBalance([cash, bank], const []), 6000.0);
    });

    test('credits add and debits subtract, per account', () {
      final txs = [
        tx(id: '1', credit: true, amount: 500, date: oct),
        tx(id: '2', credit: false, amount: 200, date: oct, account: 'a2'),
      ];
      final b = FinanceCalculator.balances([cash, bank], txs);
      expect(b['a1'], 1500.0);
      expect(b['a2'], 4800.0);
      expect(FinanceCalculator.totalBalance([cash, bank], txs), 6300.0);
    });

    test('a 500 debit lowers the total by exactly 500', () {
      final before = FinanceCalculator.totalBalance([cash, bank], const []);
      final after = FinanceCalculator.totalBalance(
        [cash, bank],
        [tx(id: '1', credit: false, amount: 500, date: oct)],
      );
      expect(before - after, 500.0);
    });

    test('deleting the last transaction restores the opening balance', () {
      final one = [tx(id: '1', credit: false, amount: 250, date: oct)];
      expect(FinanceCalculator.totalBalance([cash], one), 750.0);
      expect(FinanceCalculator.totalBalance([cash], const []), 1000.0);
    });

    test('0.1 + 0.2 does not drift', () {
      final zero = account('a1', AccountType.cash, 0);
      final txs = [
        tx(id: '1', credit: true, amount: 0.1, date: oct),
        tx(id: '2', credit: true, amount: 0.2, date: oct),
      ];
      expect(FinanceCalculator.balances([zero], txs)['a1'], 0.3);
    });

    test('transactions for an unknown account do not change any balance', () {
      final txs = [tx(id: '1', credit: true, amount: 999, date: oct, account: 'ghost')];
      expect(FinanceCalculator.totalBalance([cash, bank], txs), 6000.0);
    });

    test('balance by type', () {
      expect(FinanceCalculator.balanceOfType([cash, bank], const [], AccountType.bank), 5000.0);
      expect(FinanceCalculator.balanceOfType([cash, bank], const [], AccountType.investment), 0.0);
    });
  });

  group('month summary', () {
    test('income, expense, net and savings rate', () {
      final s = FinanceCalculator.summarize([
        tx(id: '1', credit: true, amount: 3000, date: oct),
        tx(id: '2', credit: false, amount: 1250.5, date: oct),
      ]);
      expect(s.income, 3000.0);
      expect(s.expense, 1250.5);
      expect(s.net, 1749.5);
      expect(s.savingsRate, closeTo(1749.5 / 3000, 1e-9));
    });

    test('no income means no savings rate (not a divide by zero)', () {
      final s = FinanceCalculator.summarize([tx(id: '1', credit: false, amount: 100, date: oct)]);
      expect(s.savingsRate, isNull);
      expect(s.net, -100.0);
    });

    test('empty list is all zeros', () {
      final s = FinanceCalculator.summarize(const []);
      expect(s.income, 0.0);
      expect(s.expense, 0.0);
      expect(s.net, 0.0);
    });
  });

  group('months', () {
    test('inMonth keeps only that calendar month', () {
      final txs = [
        tx(id: '1', credit: false, amount: 1, date: oct),
        tx(id: '2', credit: false, amount: 1, date: sep),
        tx(id: '3', credit: false, amount: 1, date: DateTime(2025, 10, 15)),
      ];
      expect(FinanceCalculator.inMonth(txs, DateTime(2026, 10)).map((t) => t.id), ['1']);
    });

    test('addMonths rolls the year over in both directions', () {
      expect(FinanceCalculator.addMonths(DateTime(2026, 12), 1), DateTime(2027, 1));
      expect(FinanceCalculator.addMonths(DateTime(2026, 1), -1), DateTime(2025, 12));
    });

    test('monthKey is zero padded', () {
      expect(FinanceCalculator.monthKey(DateTime(2026, 3, 9)), '202603');
    });
  });

  group('categories and weeks', () {
    test('expenseByCategory sorts largest first and shares sum to 1', () {
      final list = FinanceCalculator.expenseByCategory([
        tx(id: '1', credit: false, amount: 100, category: 'Food', date: oct),
        tx(id: '2', credit: false, amount: 300, category: 'Bills', date: oct),
        tx(id: '3', credit: false, amount: 100, category: 'Food', date: oct),
        tx(id: '4', credit: true, amount: 999, category: 'Salary', date: oct),
      ]);
      expect(list.map((c) => c.category), ['Bills', 'Food']);
      expect(list.first.amount, 300.0);
      expect(list.last.amount, 200.0);
      expect(list.fold<double>(0, (a, c) => a + c.share), closeTo(1.0, 1e-9));
    });

    test('expenseByCategory of nothing is empty', () {
      expect(FinanceCalculator.expenseByCategory(const []), isEmpty);
    });

    test('weeklyExpense buckets days 1-7, 8-14, 15-21 and 22-end', () {
      final month = DateTime(2026, 10);
      final txs = [
        tx(id: '1', credit: false, amount: 10, date: DateTime(2026, 10, 1)),
        tx(id: '2', credit: false, amount: 20, date: DateTime(2026, 10, 7)),
        tx(id: '3', credit: false, amount: 30, date: DateTime(2026, 10, 8)),
        tx(id: '4', credit: false, amount: 40, date: DateTime(2026, 10, 22)),
        tx(id: '5', credit: false, amount: 50, date: DateTime(2026, 10, 31)),
        tx(id: '6', credit: false, amount: 999, date: DateTime(2026, 9, 30)),
        tx(id: '7', credit: true, amount: 999, date: DateTime(2026, 10, 3)),
      ];
      expect(FinanceCalculator.weeklyExpense(txs, month), [30.0, 30.0, 0.0, 90.0]);
    });

    test('weeklyExpense with no data is four zeros', () {
      expect(FinanceCalculator.weeklyExpense(const [], DateTime(2026, 10)), [0.0, 0.0, 0.0, 0.0]);
    });
  });

  group('budgets', () {
    final month = DateTime(2026, 10);

    BudgetStatus statusFor(double spent, {double limit = 1000}) {
      return FinanceCalculator.budgetStatus(
        budget('Food', limit),
        [tx(id: 's', credit: false, amount: spent, date: oct)],
        month,
      );
    }

    test('half spent is ok', () {
      final s = statusFor(500);
      expect(s.ratio, 0.5);
      expect(s.remaining, 500.0);
      expect(s.level, BudgetLevel.ok);
    });

    test('80 percent is a warning', () => expect(statusFor(800).level, BudgetLevel.warning));

    test('exactly the limit is "reached", not exceeded', () {
      final s = statusFor(1000);
      expect(s.level, BudgetLevel.reached);
      expect(s.exceeded, isFalse);
      expect(s.remaining, 0.0);
    });

    test('over the limit is exceeded with negative remaining and a full bar', () {
      final s = statusFor(1000.01);
      expect(s.level, BudgetLevel.exceeded);
      expect(s.remaining, -0.01);
      expect(s.barValue, 1.0);
    });

    test('only the budget category and the selected month are counted', () {
      final txs = [
        tx(id: '1', credit: false, amount: 100, category: 'Food', date: oct),
        tx(id: '2', credit: false, amount: 900, category: 'Bills', date: oct),
        tx(id: '3', credit: false, amount: 700, category: 'Food', date: sep),
        tx(id: '4', credit: true, amount: 700, category: 'Food', date: oct),
      ];
      expect(FinanceCalculator.spentForBudget(budget('Food', 1000), txs, month), 100.0);
      expect(FinanceCalculator.spentForBudget(budget('Food', 1000), txs, DateTime(2026, 9)), 700.0);
    });

    test('Overall budget counts every expense category', () {
      final txs = [
        tx(id: '1', credit: false, amount: 100, category: 'Food', date: oct),
        tx(id: '2', credit: false, amount: 900, category: 'Bills', date: oct),
      ];
      expect(FinanceCalculator.spentForBudget(budget('Overall', 5000), txs, month), 1000.0);
    });

    test('no transactions means nothing spent', () {
      final s = FinanceCalculator.budgetStatus(budget('Food', 1000), const [], month);
      expect(s.spent, 0.0);
      expect(s.ratio, 0.0);
      expect(s.level, BudgetLevel.ok);
    });
  });
}
