import 'map_reader.dart';

/// One credit (money in) or debit (money out).
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.isCredit,
    required this.amount,
    required this.category,
    required this.accountId,
    required this.mode,
    required this.date,
    required this.createdAt,
    this.title = '',
    this.note = '',
  });

  final String id;
  final String userId;
  final bool isCredit;

  /// Always positive; [isCredit] decides the direction.
  final double amount;
  final String category;
  final String accountId;
  final String mode;

  /// The day the money moved (user chosen, local time).
  final DateTime date;
  final DateTime createdAt;
  final String title;
  final String note;

  bool get isDebit => !isCredit;
  double get signedAmount => isCredit ? amount : -amount;
  String get displayTitle => title.trim().isEmpty ? category : title.trim();

  TransactionModel copyWith({
    bool? isCredit,
    double? amount,
    String? category,
    String? accountId,
    String? mode,
    DateTime? date,
    String? title,
    String? note,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      isCredit: isCredit ?? this.isCredit,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      mode: mode ?? this.mode,
      date: date ?? this.date,
      createdAt: createdAt,
      title: title ?? this.title,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'isCredit': isCredit,
        'amount': amount,
        'category': category,
        'accountId': accountId,
        'mode': mode,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'title': title,
        'note': note,
      };

  static TransactionModel? tryFromMap(dynamic raw) {
    final r = MapReader.from(raw);
    if (r == null) return null;
    final id = r.str('id');
    final userId = r.str('userId');
    final amount = r.dbl('amount');
    final date = r.date('date') ?? r.date('createdAt');
    if (id == null || userId == null || date == null || amount <= 0) return null;
    return TransactionModel(
      id: id,
      userId: userId,
      isCredit: r.boolean('isCredit'),
      amount: amount,
      category: r.strOr('category', 'Other'),
      accountId: r.strOr('accountId', ''),
      mode: r.strOr('mode', 'Other'),
      date: date,
      createdAt: r.date('createdAt') ?? date,
      title: r.strOr('title', ''),
      note: r.strOr('note', ''),
    );
  }
}
