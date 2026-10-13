import 'package:flutter/foundation.dart';

import '../models/budget.dart';
import 'storage_service.dart';

/// Monthly budgets for the signed-in user. One budget per category.
class BudgetService extends ChangeNotifier {
  BudgetService(this._storage);

  final StorageService _storage;
  List<BudgetModel> _items = const <BudgetModel>[];

  List<BudgetModel> get budgets => _items;

  void loadForUser(String? userId) {
    if (userId == null) {
      _items = const <BudgetModel>[];
    } else {
      _items = _storage
          .readAll<BudgetModel>(_storage.budgets, BudgetModel.tryFromMap)
          .where((b) => b.userId == userId)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    notifyListeners();
  }

  bool hasCategory(String category, {String? exceptId}) =>
      _items.any((b) => b.id != exceptId && b.category == category);

  /// Returns an error message, or null on success.
  Future<String?> add(BudgetModel budget) async {
    if (hasCategory(budget.category)) {
      return 'A ${budget.category} budget already exists. Edit it instead.';
    }
    await _storage.budgets.put(budget.id, budget.toMap());
    _items = <BudgetModel>[..._items, budget];
    notifyListeners();
    return null;
  }

  Future<void> update(BudgetModel budget) async {
    await _storage.budgets.put(budget.id, budget.toMap());
    _items = _items.map((b) => b.id == budget.id ? budget : b).toList();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _storage.budgets.delete(id);
    _items = _items.where((b) => b.id != id).toList();
    notifyListeners();
  }

  Future<void> removeAllForUser(String userId) async {
    final ids = _items.where((b) => b.userId == userId).map((b) => b.id).toList();
    await _storage.budgets.deleteAll(ids);
    _items = const <BudgetModel>[];
    notifyListeners();
  }
}
