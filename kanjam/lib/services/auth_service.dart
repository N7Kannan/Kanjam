import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/crypto_utils.dart';
import '../core/validators.dart';
import '../models/user.dart';
import 'storage_service.dart';

/// Local-only accounts: sign up, sign in, session, password and app-lock PIN.
/// There is no server, so nothing here talks to the network.
class AuthService extends ChangeNotifier {
  AuthService(this._storage) {
    _restoreSession();
  }

  final StorageService _storage;
  UserModel? _user;
  bool _locked = false;
  bool _busy = false;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  /// True right after launch when the user has an app-lock PIN.
  bool get isLocked => _user != null && _locked;

  void _restoreSession() {
    final id = _storage.settings.get(AppConstants.keyCurrentUser);
    if (id is! String) return;
    final restored = UserModel.tryFromMap(_storage.users.get(id));
    if (restored != null) {
      _user = restored;
      _locked = restored.lockEnabled;
    } else {
      unawaited(_storage.settings.delete(AppConstants.keyCurrentUser));
    }
  }

  Future<void> _save(UserModel updated) async {
    await _storage.users.put(updated.id, updated.toMap());
    _user = updated;
    notifyListeners();
  }

  Future<void> _startSession(UserModel u) async {
    await _storage.settings.put(AppConstants.keyCurrentUser, u.id);
    _user = u;
    _locked = false;
    notifyListeners();
  }

  /// Returns an error message, or null on success.
  Future<String?> signUp({
    required String loginId,
    required String password,
    required String contact,
  }) async {
    if (_busy) return 'Please wait...';
    _busy = true;
    try {
      final id = Validators.normalizeUserId(loginId);
      if (_storage.users.containsKey(id)) {
        return 'This User ID is already registered. Try signing in.';
      }
      final salt = CryptoUtils.newSalt();
      final created = UserModel(
        id: id,
        loginId: loginId.trim(),
        name: '',
        passwordHash: CryptoUtils.hash(password, salt),
        salt: salt,
        contact: Validators.normalizeContact(contact),
        createdAt: DateTime.now(),
      );
      await _storage.users.put(id, created.toMap());
      await _startSession(created);
      return null;
    } catch (e) {
      debugPrint('KANJAM: signUp failed: $e');
      return 'Could not create the account. Please try again.';
    } finally {
      _busy = false;
    }
  }

  Future<String?> login(String loginId, String password) async {
    if (_busy) return 'Please wait...';
    _busy = true;
    try {
      final id = Validators.normalizeUserId(loginId);
      final found = UserModel.tryFromMap(_storage.users.get(id));
      if (found == null || !CryptoUtils.matches(password, found.salt, found.passwordHash)) {
        return 'Incorrect User ID or password';
      }
      await _startSession(found);
      return null;
    } catch (e) {
      debugPrint('KANJAM: login failed: $e');
      return 'Could not sign in. Please try again.';
    } finally {
      _busy = false;
    }
  }

  Future<void> logout() async {
    await _storage.settings.delete(AppConstants.keyCurrentUser);
    _user = null;
    _locked = false;
    notifyListeners();
  }

  // ---- profile ----------------------------------------------------------

  Future<void> updateProfile({
    required String name,
    required double monthlyIncome,
    required String contact,
  }) async {
    final u = _user;
    if (u == null) return;
    await _save(u.copyWith(
      name: name.trim(),
      monthlyIncome: monthlyIncome,
      contact: Validators.normalizeContact(contact),
    ));
  }

  /// Returns an error message, or null on success.
  Future<String?> changePassword(String current, String next) async {
    final u = _user;
    if (u == null) return 'You are signed out';
    if (!CryptoUtils.matches(current, u.salt, u.passwordHash)) {
      return 'Current password is incorrect';
    }
    final salt = CryptoUtils.newSalt();
    await _save(u.copyWith(salt: salt, passwordHash: CryptoUtils.hash(next, salt)));
    return null;
  }

  /// Local password reset: the user proves they own the account by entering
  /// the recovery contact they registered with. Returns an error or null.
  Future<String?> resetPassword({
    required String loginId,
    required String contact,
    required String newPassword,
  }) async {
    final id = Validators.normalizeUserId(loginId);
    final found = UserModel.tryFromMap(_storage.users.get(id));
    if (found == null ||
        found.contact.isEmpty ||
        found.contact != Validators.normalizeContact(contact)) {
      return 'We could not verify those details';
    }
    final salt = CryptoUtils.newSalt();
    final updated = found.copyWith(salt: salt, passwordHash: CryptoUtils.hash(newPassword, salt));
    await _storage.users.put(updated.id, updated.toMap());
    if (_user?.id == updated.id) _user = updated;
    return null;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final u = _user;
    if (u == null) return;
    await _save(u.copyWith(notificationsEnabled: enabled));
  }

  // ---- onboarding -------------------------------------------------------

  /// Saves answers immediately so onboarding survives the app being killed.
  Future<void> saveOnboardingProgress({
    required int nextStep,
    String? name,
    double? monthlyIncome,
    String? incomeSource,
    Map<String, dynamic>? draft,
  }) async {
    final u = _user;
    if (u == null) return;
    await _save(u.copyWith(
      name: name?.trim(),
      monthlyIncome: monthlyIncome,
      incomeSource: incomeSource,
      onboardingStep: nextStep < 0 ? 0 : nextStep,
      onboardingDraft: draft == null ? null : <String, dynamic>{...u.onboardingDraft, ...draft},
    ));
  }

  Future<void> markOnboardingComplete() async {
    final u = _user;
    if (u == null) return;
    await _save(u.copyWith(
      onboardingComplete: true,
      onboardingStep: 5,
      onboardingDraft: const <String, dynamic>{},
    ));
  }

  // ---- app lock ---------------------------------------------------------

  Future<void> setPin(String pin) async {
    final u = _user;
    if (u == null) return;
    final salt = CryptoUtils.newSalt();
    _locked = false;
    await _save(u.copyWith(pinHash: CryptoUtils.hash(pin, salt), pinSalt: salt));
  }

  bool verifyPin(String pin) {
    final u = _user;
    if (u == null || !u.lockEnabled) return false;
    return CryptoUtils.matches(pin, u.pinSalt!, u.pinHash!);
  }

  bool unlockWithPin(String pin) {
    if (!verifyPin(pin)) return false;
    _locked = false;
    notifyListeners();
    return true;
  }

  Future<void> clearPin() async {
    final u = _user;
    if (u == null) return;
    _locked = false;
    await _save(u.copyWith(clearPin: true));
  }

  /// "Forgot PIN": the account password proves ownership and removes the lock.
  Future<bool> unlockWithPassword(String password) async {
    final u = _user;
    if (u == null || !CryptoUtils.matches(password, u.salt, u.passwordHash)) return false;
    await clearPin();
    return true;
  }
}
