import 'package:flutter/foundation.dart';

import '../models/goal.dart';
import 'storage_service.dart';

/// Savings goals for the signed-in user.
class GoalService extends ChangeNotifier {
  GoalService(this._storage);

  final StorageService _storage;
  List<GoalModel> _items = const <GoalModel>[];

  List<GoalModel> get goals => _items;

  GoalModel? byId(String id) {
    for (final g in _items) {
      if (g.id == id) return g;
    }
    return null;
  }

  void loadForUser(String? userId) {
    if (userId == null) {
      _items = const <GoalModel>[];
    } else {
      _items = _storage
          .readAll<GoalModel>(_storage.goals, GoalModel.tryFromMap)
          .where((g) => g.userId == userId)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    notifyListeners();
  }

  bool _nameTaken(String name, {String? exceptId}) {
    final key = name.trim().toLowerCase();
    return _items.any((g) => g.id != exceptId && g.name.trim().toLowerCase() == key);
  }

  /// Returns an error message, or null on success.
  Future<String?> add(GoalModel goal) async {
    if (_nameTaken(goal.name)) return 'You already have a goal named "${goal.name}"';
    await _storage.goals.put(goal.id, goal.toMap());
    _items = <GoalModel>[..._items, goal];
    notifyListeners();
    return null;
  }

  Future<String?> update(GoalModel goal) async {
    if (_nameTaken(goal.name, exceptId: goal.id)) {
      return 'You already have a goal named "${goal.name}"';
    }
    await _storage.goals.put(goal.id, goal.toMap());
    _items = _items.map((g) => g.id == goal.id ? goal : g).toList();
    notifyListeners();
    return null;
  }

  Future<void> remove(String id) async {
    await _storage.goals.delete(id);
    _items = _items.where((g) => g.id != id).toList();
    notifyListeners();
  }

  Future<void> removeAllForUser(String userId) async {
    final ids = _items.where((g) => g.userId == userId).map((g) => g.id).toList();
    await _storage.goals.deleteAll(ids);
    _items = const <GoalModel>[];
    notifyListeners();
  }
}
