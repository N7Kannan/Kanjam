import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import 'storage_service.dart';

/// Transactions for the signed-in user, newest first.
class TransactionService extends ChangeNotifier {
  TransactionService(this._storage);

  final StorageService _storage;
  List<TransactionModel> _items = const <TransactionModel>[];

  List<TransactionModel> get all => _items;

  static int _newestFirst(TransactionModel a, TransactionModel b) {
    final c = b.date.compareTo(a.date);
    return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
  }

  void loadForUser(String? userId) {
    if (userId == null) {
      _items = const <TransactionModel>[];
    } else {
      _items = _storage
          .readAll<TransactionModel>(_storage.transactions, TransactionModel.tryFromMap)
          .where((t) => t.userId == userId)
          .toList()
        ..sort(_newestFirst);
    }
    notifyListeners();
  }

  TransactionModel? byId(String id) {
    for (final t in _items) {
      if (t.id == id) return t;
    }
    return null;
  }

  int countForAccount(String accountId) => _items.where((t) => t.accountId == accountId).length;

  Future<void> add(TransactionModel tx) async {
    await _storage.transactions.put(tx.id, tx.toMap());
    _items = <TransactionModel>[..._items, tx]..sort(_newestFirst);
    notifyListeners();
  }

  Future<void> update(TransactionModel tx) async {
    await _storage.transactions.put(tx.id, tx.toMap());
    _items = _items.map((t) => t.id == tx.id ? tx : t).toList()..sort(_newestFirst);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _storage.transactions.delete(id);
    _items = _items.where((t) => t.id != id).toList();
    notifyListeners();
  }

  Future<void> removeAllForUser(String userId) async {
    final ids = _storage
        .readAll<TransactionModel>(_storage.transactions, TransactionModel.tryFromMap)
        .where((t) => t.userId == userId)
        .map((t) => t.id)
        .toList();
    await _storage.transactions.deleteAll(ids);
    _items = const <TransactionModel>[];
    notifyListeners();
  }

  /// Filters the list. [from] and [to] are inclusive calendar days.
  List<TransactionModel> filter({
    bool? credit,
    DateTime? from,
    DateTime? to,
    String query = '',
  }) {
    final q = query.trim().toLowerCase();
    final start = from == null ? null : DateTime(from.year, from.month, from.day);
    final endExclusive = to == null ? null : DateTime(to.year, to.month, to.day + 1);
    return _items.where((t) {
      if (credit != null && t.isCredit != credit) return false;
      if (start != null && t.date.isBefore(start)) return false;
      if (endExclusive != null && !t.date.isBefore(endExclusive)) return false;
      if (q.isNotEmpty) {
        final hay = '${t.title} ${t.category} ${t.note} ${t.mode}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }
}
