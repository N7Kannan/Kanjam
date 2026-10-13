import 'package:intl/intl.dart';

import 'constants.dart';
import 'money.dart';

/// Display formatting. Amounts use Indian digit grouping (12,34,567.00).
class Fmt {
  Fmt._();

  static final NumberFormat _withPaise = NumberFormat('#,##,##0.00', 'en_IN');
  static final NumberFormat _whole = NumberFormat('#,##,##0', 'en_IN');
  static final DateFormat _day = DateFormat('dd MMM yyyy');
  static final DateFormat _dayShort = DateFormat('dd MMM');
  static final DateFormat _month = DateFormat('MMMM yyyy');
  static final DateFormat _long = DateFormat('EEEE, MMMM d');

  /// Rupee amount, e.g. "₹1,234.50" or "-₹99.00". [signed] adds a leading
  /// plus sign for positive values.
  static String money(double value, {bool decimals = true, bool signed = false}) {
    final v = round2(value);
    final negative = v < 0;
    final body = (decimals ? _withPaise : _whole).format(v.abs());
    final sign = negative ? '-' : (signed && v > 0 ? '+' : '');
    return '$sign${AppConstants.currencySymbol}$body';
  }

  /// Short form for chart labels: 950, 1.2K, 3.4L, 1.5Cr.
  static String compact(double value) {
    final v = value.abs();
    String body;
    if (v >= 10000000) {
      body = '${_trim(v / 10000000)}Cr';
    } else if (v >= 100000) {
      body = '${_trim(v / 100000)}L';
    } else if (v >= 1000) {
      body = '${_trim(v / 1000)}K';
    } else {
      body = _trim(v);
    }
    return '${value < 0 ? '-' : ''}${AppConstants.currencySymbol}$body';
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  static String percent(double ratio, {int digits = 0}) =>
      '${(ratio * 100).toStringAsFixed(digits)}%';

  static String date(DateTime d) => _day.format(d);
  static String dateShort(DateTime d) => _dayShort.format(d);
  static String monthYear(DateTime d) => _month.format(d);
  static String longDate(DateTime d) => _long.format(d);

  static String relative(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = n.difference(d);
    if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return date(d);
  }

  static String greeting({DateTime? now}) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
