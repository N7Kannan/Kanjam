import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Log framework and async errors instead of letting one bad frame or future
  // take the whole app down.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (Object error, StackTrace stack) {
    debugPrint('KANJAM uncaught error: $error\n$stack');
    return true;
  };

  runApp(const KanjamBootstrap());
}
