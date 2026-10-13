import 'package:flutter_test/flutter_test.dart';
import 'package:kanjam/models/account.dart';
import 'package:kanjam/models/budget.dart';
import 'package:kanjam/models/goal.dart';
import 'package:kanjam/models/notification_item.dart';
import 'package:kanjam/models/transaction.dart';
import 'package:kanjam/models/user.dart';

void main() {
  final created = DateTime(2026, 10, 1, 9, 30);

  // Hive returns Map<dynamic, dynamic>; mimic that when reading back.
  Map<dynamic, dynamic> asHive(Map<String, dynamic> m) => Map<dynamic, dynamic>.from(m);

  test('transaction round trip', () {
    final t = TransactionModel(
      id: 't1',
      userId: 'u',
      isCredit: false,
      amount: 249.5,
      category: 'Food',
      accountId: 'a1',
      mode: 'UPI',
      date: DateTime(2026, 10, 3),
      createdAt: created,
      title: 'Lunch',
      note: 'With friends',
    );
    final back = TransactionModel.tryFromMap(asHive(t.toMap()))!;
    expect(back.id, 't1');
    expect(back.amount, 249.5);
    expect(back.isCredit, isFalse);
    expect(back.signedAmount, -249.5);
    expect(back.date, DateTime(2026, 10, 3));
    expect(back.title, 'Lunch');
    expect(back.note, 'With friends');
    expect(back.displayTitle, 'Lunch');
  });

  test('transaction without a title shows its category', () {
    final t = TransactionModel(
      id: 't',
      userId: 'u',
      isCredit: true,
      amount: 10,
      category: 'Gift',
      accountId: 'a',
      mode: 'Cash',
      date: created,
      createdAt: created,
    );
    expect(t.displayTitle, 'Gift');
  });

  group('corrupt or partial records are skipped, never thrown', () {
    test('not a map', () {
      expect(TransactionModel.tryFromMap(null), isNull);
      expect(TransactionModel.tryFromMap('oops'), isNull);
      expect(AccountModel.tryFromMap(42), isNull);
      expect(GoalModel.tryFromMap(<int>[1]), isNull);
      expect(BudgetModel.tryFromMap(null), isNull);
      expect(NotificationItem.tryFromMap(null), isNull);
      expect(UserModel.tryFromMap(null), isNull);
    });

    test('zero or missing amount', () {
      expect(
        TransactionModel.tryFromMap(<String, dynamic>{
          'id': 't', 'userId': 'u', 'amount': 0, 'date': created.toIso8601String(),
        }),
        isNull,
      );
      expect(
        TransactionModel.tryFromMap(<String, dynamic>{'id': 't', 'userId': 'u'}),
        isNull,
      );
    });

    test('wrongly typed numbers fall back instead of crashing', () {
      final t = TransactionModel.tryFromMap(<String, dynamic>{
        'id': 't',
        'userId': 'u',
        'amount': '125.5',
        'isCredit': 'true',
        'date': created.toIso8601String(),
      })!;
      expect(t.amount, 125.5);
      expect(t.isCredit, isTrue);
      expect(t.category, 'Other');
    });

    test('non-positive budget limit or goal target is dropped', () {
      expect(
        BudgetModel.tryFromMap(<String, dynamic>{
          'id': 'b', 'userId': 'u', 'category': 'Food', 'monthlyLimit': 0,
        }),
        isNull,
      );
      expect(
        GoalModel.tryFromMap(<String, dynamic>{
          'id': 'g', 'userId': 'u', 'name': 'Trip', 'targetAmount': -5,
        }),
        isNull,
      );
    });

    test('unknown enum values fall back to a safe default', () {
      final a = AccountModel.tryFromMap(<String, dynamic>{
        'id': 'a', 'userId': 'u', 'type': 'crypto', 'openingBalance': 10,
      })!;
      expect(a.type, AccountType.bank);
      final n = NotificationItem.tryFromMap(<String, dynamic>{
        'id': 'n', 'userId': 'u', 'title': 'Hi', 'kind': 'weird',
      })!;
      expect(n.kind, NotificationKind.system);
    });
  });

  group('goal', () {
    GoalModel goal(double current, {double target = 1000}) => GoalModel(
          id: 'g',
          userId: 'u',
          name: 'Laptop',
          targetAmount: target,
          currentAmount: current,
          createdAt: created,
        );

    test('progress and remaining', () {
      expect(goal(250).progress, 0.25);
      expect(goal(250).remaining, 750.0);
      expect(goal(250).isCompleted, isFalse);
    });

    test('reaching or passing the target completes it and caps progress at 100%', () {
      expect(goal(1000).isCompleted, isTrue);
      expect(goal(1500).progress, 1.0);
      expect(goal(1500).remaining, 0.0);
    });

    test('round trip keeps an optional target date', () {
      final g = goal(100).copyWith(targetDate: DateTime(2027, 5, 1));
      final back = GoalModel.tryFromMap(asHive(g.toMap()))!;
      expect(back.targetDate, DateTime(2027, 5, 1));
      expect(goal(100).copyWith(clearTargetDate: true).targetDate, isNull);
    });
  });

  group('user', () {
    UserModel user({String? pinHash, String? pinSalt}) => UserModel(
          id: 'kannan',
          loginId: 'Kannan',
          name: 'Kannan Raj',
          passwordHash: 'h',
          salt: 's',
          contact: 'a@b.co',
          createdAt: created,
          pinHash: pinHash,
          pinSalt: pinSalt,
        );

    test('first name and initial', () {
      expect(user().firstName, 'Kannan');
      expect(user().initial, 'K');
    });

    test('lock is on only when both pin fields exist; clearPin removes it', () {
      expect(user().lockEnabled, isFalse);
      final locked = user(pinHash: 'x', pinSalt: 'y');
      expect(locked.lockEnabled, isTrue);
      expect(locked.copyWith(clearPin: true).lockEnabled, isFalse);
    });

    test('round trip keeps the onboarding draft', () {
      final u = user().copyWith(
        onboardingStep: 3,
        onboardingDraft: <String, dynamic>{'cash': 500.0, 'bankAdded': true},
      );
      final back = UserModel.tryFromMap(asHive(u.toMap()))!;
      expect(back.onboardingStep, 3);
      expect(back.onboardingDraft['cash'], 500.0);
      expect(back.onboardingDraft['bankAdded'], true);
    });

    test('a record without credentials is unusable', () {
      expect(UserModel.tryFromMap(<String, dynamic>{'id': 'x'}), isNull);
    });

    test('out of range onboarding step is clamped', () {
      final back = UserModel.tryFromMap(<String, dynamic>{
        'id': 'x', 'passwordHash': 'h', 'salt': 's', 'onboardingStep': 99,
      })!;
      expect(back.onboardingStep, 5);
    });
  });
}
