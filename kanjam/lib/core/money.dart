import 'constants.dart';

/// Rounds to 2 decimal places (paise) to stop floating point drift.
double round2(double v) => (v * 100).roundToDouble() / 100;

class AmountParser {
  AmountParser._();

  /// Parses user text such as "1,250.50" or "Rs 500". Returns null when the
  /// text is empty or not a finite number.
  static double? tryParse(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp('[\u20B9,\\s]'), '');
    if (cleaned.isEmpty) return null;
    final v = double.tryParse(cleaned);
    if (v == null || v.isNaN || v.isInfinite) return null;
    return round2(v);
  }

  static bool isWithinLimit(double v) => v <= AppConstants.maxAmount;
}
