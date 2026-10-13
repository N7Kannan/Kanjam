import 'constants.dart';
import 'formatters.dart';
import 'money.dart';

/// Form validators. Each returns an error message, or null when valid.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phone = RegExp(r'^\+?[0-9]{10,13}$');

  /// Login ids are stored trimmed and lower-cased.
  static String normalizeUserId(String raw) => raw.trim().toLowerCase();

  static String? name(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Please enter your name';
    if (t.length > 40) return 'Name is too long (max 40 characters)';
    return null;
  }

  static String? userId(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Please enter your User ID';
    if (t.length < AppConstants.minUserIdLength) {
      return 'User ID must be at least ${AppConstants.minUserIdLength} characters';
    }
    if (t.length > 60) return 'User ID is too long';
    if (t.contains(RegExp(r'\s'))) return 'User ID cannot contain spaces';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Please enter a password';
    if (v.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  static String? loginPassword(String? v) =>
      (v == null || v.isEmpty) ? 'Please enter your password' : null;

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  /// Recovery contact: an email address or a 10-13 digit phone number.
  static String? contact(String? v) {
    final t = (v ?? '').trim().replaceAll(RegExp(r'[\s-]'), '');
    if (t.isEmpty) return 'Enter an email or phone number for password recovery';
    if (_email.hasMatch(t) || _phone.hasMatch(t)) return null;
    return 'Enter a valid email or phone number';
  }

  static String normalizeContact(String raw) =>
      raw.trim().replaceAll(RegExp(r'[\s-]'), '').toLowerCase();

  static String? requiredText(String? v, String message, {int maxLength = 60}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return message;
    if (t.length > maxLength) return 'Too long (max $maxLength characters)';
    return null;
  }

  /// Money amount. [allowZero] is for balances that may legitimately be 0.
  static String? amount(
    String? v, {
    bool allowZero = false,
    bool optional = false,
    String emptyMessage = 'Enter amount',
  }) {
    final raw = v?.trim() ?? '';
    if (raw.isEmpty) return optional ? null : emptyMessage;
    final parsed = AmountParser.tryParse(raw);
    if (parsed == null) return 'Enter a valid amount';
    if (parsed < 0) return 'Amount cannot be negative';
    if (parsed == 0 && !allowZero) return 'Amount must be greater than 0';
    if (!AmountParser.isWithinLimit(parsed)) {
      return 'Amount is too large (max ${Fmt.money(AppConstants.maxAmount, decimals: false)})';
    }
    return null;
  }
}
