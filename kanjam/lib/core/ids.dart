/// Collision-free ids, even when two taps land in the same microsecond.
class IdGen {
  IdGen._();
  static int _counter = 0;

  static String next(String prefix) {
    _counter = (_counter + 1) % 1000000;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }
}
