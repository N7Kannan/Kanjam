import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted, iterated SHA-256 for local passwords and the app-lock PIN.
/// This protects against casual inspection of the Hive file. It is not a
/// substitute for server-side authentication (the app has no server).
class CryptoUtils {
  CryptoUtils._();

  static String newSalt([int bytes = 16]) {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(bytes, (_) => random.nextInt(256)));
  }

  static String hash(String secret, String salt) {
    final saltBytes = utf8.encode(salt);
    List<int> digest = sha256.convert(utf8.encode('$salt:$secret')).bytes;
    for (var i = 0; i < 2000; i++) {
      digest = sha256.convert(<int>[...digest, ...saltBytes]).bytes;
    }
    return base64UrlEncode(digest);
  }

  static bool matches(String secret, String salt, String expectedHash) {
    return constantTimeEquals(hash(secret, salt), expectedHash);
  }

  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
