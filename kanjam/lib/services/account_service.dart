import 'package:flutter/foundation.dart';

import '../models/account.dart';
import 'storage_service.dart';

/// Accounts for the signed-in user (cash, bank, investments).
class AccountService extends ChangeNotifier {
  AccountService(this._storage);

  final StorageService _storage;
  String? _userId;
  List<AccountModel> _items = const <AccountModel>[];

  List<AccountModel> get accounts => _items;

  AccountModel? byId(String id) {
    for (final a in _items) {
      if (a.id == id) return a;
    }
    return null;
  }

  void loadForUser(String? userId) {
    _userId = userId;
    if (userId == null) {
      _items = const <AccountModel>[];
    } else {
      final list = _storage
          .readAll<AccountModel>(_storage.accounts, AccountModel.tryFromMap)
          .where((a) => a.userId == userId)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _items = list;
    }
    notifyListeners();
  }

  bool _nameTaken(String name, {String? exceptId}) {
    final key = name.trim().toLowerCase();
    return _items.any((a) => a.id != exceptId && a.name.trim().toLowerCase() == key);
  }

  /// Returns an error message, or null on success.
  Future<String?> add(AccountModel account) async {
    if (_nameTaken(account.name)) return 'You already have an account named "${account.name}"';
    await _storage.accounts.put(account.id, account.toMap());
    _items = <AccountModel>[..._items, account];
    notifyListeners();
    return null;
  }

  Future<String?> update(AccountModel account) async {
    if (_nameTaken(account.name, exceptId: account.id)) {
      return 'You already have an account named "${account.name}"';
    }
    await _storage.accounts.put(account.id, account.toMap());
    _items = _items.map((a) => a.id == account.id ? account : a).toList();
    notifyListeners();
    return null;
  }

  Future<void> remove(String id) async {
    await _storage.accounts.delete(id);
    _items = _items.where((a) => a.id != id).toList();
    notifyListeners();
  }

  /// Creates onboarding accounts. Ids are fixed per user, so running this twice
  /// (for example after a crash during onboarding) never creates duplicates.
  Future<void> upsertAll(List<AccountModel> accounts) async {
    for (final a in accounts) {
      await _storage.accounts.put(a.id, a.toMap());
    }
    final ids = accounts.map((a) => a.id).toSet();
    _items = <AccountModel>[
      ..._items.where((a) => !ids.contains(a.id)),
      ...accounts,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();
  }

  String? get currentUserId => _userId;
}
