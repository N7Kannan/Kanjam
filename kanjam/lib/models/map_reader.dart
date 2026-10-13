/// Reads loosely-typed values out of a stored Hive map without throwing.
/// Hive hands back `Map<dynamic, dynamic>`, and old or damaged records may have
/// missing or wrongly typed fields, so every accessor falls back to a default.
class MapReader {
  MapReader._(this._m);

  final Map<String, dynamic> _m;

  static MapReader? from(dynamic raw) {
    if (raw is! Map) return null;
    return MapReader._(
      raw.map<String, dynamic>((k, v) => MapEntry<String, dynamic>(k.toString(), v)),
    );
  }

  String? str(String key) {
    final v = _m[key];
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  String strOr(String key, String fallback) => str(key) ?? fallback;

  double dbl(String key, [double fallback = 0]) {
    final v = _m[key];
    double? out;
    if (v is num) {
      out = v.toDouble();
    } else if (v is String) {
      out = double.tryParse(v);
    }
    if (out == null || out.isNaN || out.isInfinite) return fallback;
    return out;
  }

  int integer(String key, [int fallback = 0]) {
    final v = _m[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  bool boolean(String key, [bool fallback = false]) {
    final v = _m[key];
    if (v is bool) return v;
    if (v is String) {
      if (v == 'true') return true;
      if (v == 'false') return false;
    }
    return fallback;
  }

  DateTime? date(String key) {
    final v = _m[key];
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  Map<String, dynamic> map(String key) {
    final v = _m[key];
    if (v is Map) {
      return v.map<String, dynamic>((k, val) => MapEntry<String, dynamic>(k.toString(), val));
    }
    return <String, dynamic>{};
  }
}
