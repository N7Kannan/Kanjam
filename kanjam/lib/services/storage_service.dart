import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants.dart';

/// Owns Hive: initialises it once, opens every box before anything reads from
/// it, and recovers from a corrupt box instead of crashing at startup.
///
/// Records are stored as plain maps (see each model's toMap/tryFromMap), so no
/// generated TypeAdapters or build_runner step is needed.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  bool _ready = false;

  /// True when a box could not be opened and was reset. The UI shows a notice.
  bool recoveredFromCorruption = false;

  late Box<dynamic> users;
  late Box<dynamic> accounts;
  late Box<dynamic> transactions;
  late Box<dynamic> budgets;
  late Box<dynamic> goals;
  late Box<dynamic> notifications;
  late Box<dynamic> settings;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    users = await _open(AppConstants.usersBox);
    accounts = await _open(AppConstants.accountsBox);
    transactions = await _open(AppConstants.transactionsBox);
    budgets = await _open(AppConstants.budgetsBox);
    goals = await _open(AppConstants.goalsBox);
    notifications = await _open(AppConstants.notificationsBox);
    settings = await _open(AppConstants.settingsBox);

    if (settings.get(AppConstants.keySchemaVersion) != AppConstants.schemaVersion) {
      await settings.put(AppConstants.keySchemaVersion, AppConstants.schemaVersion);
    }
    _ready = true;
  }

  Future<Box<dynamic>> _open(String name) async {
    try {
      return await Hive.openBox<dynamic>(name);
    } catch (e) {
      debugPrint('KANJAM: could not open box "$name" ($e); resetting it.');
      recoveredFromCorruption = true;
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {
        // Nothing more we can do; the reopen below reports the real failure.
      }
      return Hive.openBox<dynamic>(name);
    }
  }

  /// Reads every record in [box], skipping (and logging) unreadable ones.
  List<T> readAll<T>(Box<dynamic> box, T? Function(dynamic raw) parse) {
    final out = <T>[];
    var skipped = 0;
    for (final raw in box.values) {
      final parsed = parse(raw);
      if (parsed == null) {
        skipped++;
      } else {
        out.add(parsed);
      }
    }
    if (skipped > 0) {
      debugPrint('KANJAM: skipped $skipped unreadable record(s) in "${box.name}".');
    }
    return out;
  }
}
