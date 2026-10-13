import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/notification_item.dart';
import 'storage_service.dart';

/// The in-app notification centre. KANJAM has no server, so these are local
/// alerts the app raises itself (budgets, goals, new transactions).
class NotificationService extends ChangeNotifier {
  NotificationService(this._storage);

  final StorageService _storage;
  List<NotificationItem> _items = const <NotificationItem>[];

  /// Newest first.
  List<NotificationItem> get items => _items;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  void loadForUser(String? userId) {
    if (userId == null) {
      _items = const <NotificationItem>[];
    } else {
      _items = _storage
          .readAll<NotificationItem>(_storage.notifications, NotificationItem.tryFromMap)
          .where((n) => n.userId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    notifyListeners();
  }

  /// Adds the notification unless one with the same id already exists.
  /// Returns true when it was added.
  Future<bool> addIfAbsent(NotificationItem item) async {
    if (_items.any((n) => n.id == item.id)) return false;
    await _storage.notifications.put(item.id, item.toMap());
    final next = <NotificationItem>[item, ..._items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (next.length > AppConstants.maxNotifications) {
      final overflow = next.sublist(AppConstants.maxNotifications);
      await _storage.notifications.deleteAll(overflow.map((n) => n.id).toList());
      _items = next.sublist(0, AppConstants.maxNotifications);
    } else {
      _items = next;
    }
    notifyListeners();
    return true;
  }

  Future<void> markRead(String id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index < 0 || _items[index].isRead) return;
    final updated = _items[index].copyWith(isRead: true);
    await _storage.notifications.put(id, updated.toMap());
    _items = List<NotificationItem>.of(_items)..[index] = updated;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    final unread = _items.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    for (final n in unread) {
      await _storage.notifications.put(n.id, n.copyWith(isRead: true).toMap());
    }
    _items = _items.map((n) => n.isRead ? n : n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  /// Updates the list first, then the database: a swiped-away Dismissible
  /// must disappear from the widget tree in the same frame.
  Future<void> remove(String id) async {
    _items = _items.where((n) => n.id != id).toList();
    notifyListeners();
    await _storage.notifications.delete(id);
  }

  Future<void> clearAll() async {
    await _storage.notifications.deleteAll(_items.map((n) => n.id).toList());
    _items = const <NotificationItem>[];
    notifyListeners();
  }
}
