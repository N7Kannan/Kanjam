import 'map_reader.dart';

/// A savings goal. Money added to a goal is tracked here; it does not move
/// money between accounts.
class GoalModel {
  const GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.createdAt,
    this.targetDate,
  });

  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime createdAt;
  final DateTime? targetDate;

  bool get isCompleted => targetAmount > 0 && currentAmount >= targetAmount;

  /// 0.0 - 1.0 for progress bars.
  double get progress {
    if (targetAmount <= 0) return 0;
    final p = currentAmount / targetAmount;
    if (p.isNaN || p < 0) return 0;
    return p > 1 ? 1 : p;
  }

  double get remaining {
    final r = targetAmount - currentAmount;
    return r < 0 ? 0 : r;
  }

  GoalModel copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    bool clearTargetDate = false,
  }) {
    return GoalModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      createdAt: createdAt,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'createdAt': createdAt.toIso8601String(),
        'targetDate': targetDate?.toIso8601String(),
      };

  static GoalModel? tryFromMap(dynamic raw) {
    final r = MapReader.from(raw);
    if (r == null) return null;
    final id = r.str('id');
    final userId = r.str('userId');
    final name = r.str('name');
    final target = r.dbl('targetAmount');
    if (id == null || userId == null || name == null || target <= 0) return null;
    final current = r.dbl('currentAmount');
    return GoalModel(
      id: id,
      userId: userId,
      name: name,
      targetAmount: target,
      currentAmount: current < 0 ? 0 : current,
      createdAt: r.date('createdAt') ?? DateTime.now(),
      targetDate: r.date('targetDate'),
    );
  }
}
