import 'map_reader.dart';

enum NotificationKind { budget, goal, transaction, system }

/// An entry in the in-app notification centre.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.kind,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationKind kind;
  final DateTime createdAt;
  final bool isRead;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        userId: userId,
        title: title,
        message: message,
        kind: kind,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'title': title,
        'message': message,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  static NotificationItem? tryFromMap(dynamic raw) {
    final r = MapReader.from(raw);
    if (r == null) return null;
    final id = r.str('id');
    final userId = r.str('userId');
    final title = r.str('title');
    if (id == null || userId == null || title == null) return null;
    final kindName = r.strOr('kind', 'system');
    final kind = NotificationKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => NotificationKind.system,
    );
    return NotificationItem(
      id: id,
      userId: userId,
      title: title,
      message: r.strOr('message', ''),
      kind: kind,
      createdAt: r.date('createdAt') ?? DateTime.now(),
      isRead: r.boolean('isRead'),
    );
  }
}
