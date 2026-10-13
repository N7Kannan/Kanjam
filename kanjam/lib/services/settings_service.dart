import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'storage_service.dart';

/// App-wide (not per-user) settings. Currently the theme.
class SettingsService extends ChangeNotifier {
  SettingsService(this._storage) {
    final raw = _storage.settings.get(AppConstants.keyThemeMode);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.dark,
    );
  }

  final StorageService _storage;
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.settings.put(AppConstants.keyThemeMode, mode.name);
  }
}
