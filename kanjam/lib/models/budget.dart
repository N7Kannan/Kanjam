import 'map_reader.dart';

/// A recurring monthly spending limit for one category (or "Overall").
class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.monthlyLimit,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String category;
  final double monthlyLimit;
  final DateTime createdAt;

  BudgetModel copyWith({double? monthlyLimit}) => BudgetModel(
        id: id,
        userId: userId,
        category: category,
        monthlyLimit: monthlyLimit ?? this.monthlyLimit,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'category': category,
        'monthlyLimit': monthlyLimit,
        'createdAt': createdAt.toIso8601String(),
      };

  static BudgetModel? tryFromMap(dynamic raw) {
    final r = MapReader.from(raw);
    if (r == null) return null;
    final id = r.str('id');
    final userId = r.str('userId');
    final category = r.str('category');
    final limit = r.dbl('monthlyLimit');
    if (id == null || userId == null || category == null || limit <= 0) return null;
    return BudgetModel(
      id: id,
      userId: userId,
      category: category,
      monthlyLimit: limit,
      createdAt: r.date('createdAt') ?? DateTime.now(),
    );
  }
}
