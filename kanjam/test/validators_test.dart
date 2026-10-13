import 'package:flutter_test/flutter_test.dart';
import 'package:kanjam/core/money.dart';
import 'package:kanjam/core/validators.dart';

void main() {
  group('amount', () {
    test('empty is rejected unless optional', () {
      expect(Validators.amount(''), 'Enter amount');
      expect(Validators.amount('   '), 'Enter amount');
      expect(Validators.amount('', optional: true), isNull);
    });

    test('zero is rejected unless allowed', () {
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('0.00'), isNotNull);
      expect(Validators.amount('0', allowZero: true), isNull);
    });

    test('negative and non numeric values are rejected', () {
      expect(Validators.amount('-5'), isNotNull);
      expect(Validators.amount('abc'), 'Enter a valid amount');
      expect(Validators.amount('.'), 'Enter a valid amount');
    });

    test('thousands separators and a rupee sign are accepted', () {
      expect(Validators.amount('1,250.50'), isNull);
      expect(Validators.amount('\u20B9 500'), isNull);
    });

    test('very large amounts are limited', () {
      expect(Validators.amount('9999999999.99'), isNull);
      expect(Validators.amount('99999999999'), isNotNull);
    });
  });

  group('amount parsing', () {
    test('rounds to paise and handles bad input', () {
      expect(AmountParser.tryParse('12.345'), 12.35);
      expect(AmountParser.tryParse('1,000'), 1000.0);
      expect(AmountParser.tryParse(''), isNull);
      expect(AmountParser.tryParse(null), isNull);
      expect(AmountParser.tryParse('NaN'), isNull);
      expect(AmountParser.tryParse('Infinity'), isNull);
    });

    test('round2 stops floating point drift', () {
      expect(round2(0.1 + 0.2), 0.3);
    });
  });

  group('account fields', () {
    test('user id', () {
      expect(Validators.userId(''), isNotNull);
      expect(Validators.userId('ab'), 'User ID must be at least 3 characters');
      expect(Validators.userId('a b c'), isNotNull);
      expect(Validators.userId('abc'), isNull);
      expect(Validators.userId('kannan@example.com'), isNull);
    });

    test('user id is normalised for lookups', () {
      expect(Validators.normalizeUserId('  Kannan@Example.COM '), 'kannan@example.com');
    });

    test('password', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), 'Password must be at least 6 characters');
      expect(Validators.password('123456'), isNull);
    });

    test('confirm password', () {
      expect(Validators.confirmPassword('', 'secret1'), isNotNull);
      expect(Validators.confirmPassword('secret2', 'secret1'), 'Passwords do not match');
      expect(Validators.confirmPassword('secret1', 'secret1'), isNull);
    });

    test('recovery contact accepts email or phone only', () {
      expect(Validators.contact('me@example.com'), isNull);
      expect(Validators.contact('98765 43210'), isNull);
      expect(Validators.contact('+919876543210'), isNull);
      expect(Validators.contact('abc'), isNotNull);
      expect(Validators.contact(''), isNotNull);
    });

    test('name', () {
      expect(Validators.name(''), 'Please enter your name');
      expect(Validators.name('Kannan'), isNull);
    });
  });
}
