import 'package:flutter_test/flutter_test.dart';
import 'package:kanjam/core/crypto_utils.dart';
import 'package:kanjam/core/formatters.dart';

void main() {
  group('Fmt.money', () {
    test('Indian digit grouping with paise', () {
      expect(Fmt.money(1234567.5), '\u20B912,34,567.50');
      expect(Fmt.money(0), '\u20B90.00');
      expect(Fmt.money(999), '\u20B9999.00');
    });

    test('negative and signed values', () {
      expect(Fmt.money(-99), '-\u20B999.00');
      expect(Fmt.money(50, signed: true), '+\u20B950.00');
      expect(Fmt.money(-0.001), '\u20B90.00');
    });

    test('whole rupees', () {
      expect(Fmt.money(1234, decimals: false), '\u20B91,234');
    });

    test('very large amounts do not break', () {
      expect(Fmt.money(9999999999.99), '\u20B99,99,99,99,999.99');
    });
  });

  test('Fmt.compact', () {
    expect(Fmt.compact(950), '\u20B9950');
    expect(Fmt.compact(1200), '\u20B91.2K');
    expect(Fmt.compact(1000), '\u20B91K');
    expect(Fmt.compact(150000), '\u20B91.5L');
    expect(Fmt.compact(25000000), '\u20B92.5Cr');
  });

  test('Fmt.percent', () {
    expect(Fmt.percent(0.256), '26%');
    expect(Fmt.percent(0.256, digits: 1), '25.6%');
  });

  test('Fmt.greeting', () {
    expect(Fmt.greeting(now: DateTime(2026, 1, 1, 9)), 'Good Morning');
    expect(Fmt.greeting(now: DateTime(2026, 1, 1, 13)), 'Good Afternoon');
    expect(Fmt.greeting(now: DateTime(2026, 1, 1, 20)), 'Good Evening');
  });

  test('Fmt.relative', () {
    final now = DateTime(2026, 1, 10, 12);
    expect(Fmt.relative(now.subtract(const Duration(seconds: 30)), now: now), 'Just now');
    expect(Fmt.relative(now.subtract(const Duration(minutes: 5)), now: now), '5 min ago');
    expect(Fmt.relative(now.subtract(const Duration(hours: 3)), now: now), '3 h ago');
    expect(Fmt.relative(now.subtract(const Duration(days: 2)), now: now), '2 d ago');
    expect(Fmt.relative(DateTime(2025, 12, 31), now: now), '31 Dec 2025');
  });

  group('CryptoUtils', () {
    test('hash is deterministic and salt dependent', () {
      final a = CryptoUtils.hash('secret', 'salt1');
      expect(CryptoUtils.hash('secret', 'salt1'), a);
      expect(CryptoUtils.hash('secret', 'salt2'), isNot(a));
      expect(CryptoUtils.hash('Secret', 'salt1'), isNot(a));
    });

    test('matches only the right secret', () {
      final salt = CryptoUtils.newSalt();
      final hash = CryptoUtils.hash('Password123', salt);
      expect(CryptoUtils.matches('Password123', salt, hash), isTrue);
      expect(CryptoUtils.matches('password123', salt, hash), isFalse);
      expect(hash.contains('Password123'), isFalse);
    });

    test('salts are unique', () {
      expect(CryptoUtils.newSalt(), isNot(CryptoUtils.newSalt()));
    });
  });
}
