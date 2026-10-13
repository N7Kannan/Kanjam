import 'map_reader.dart';

enum AccountType { cash, bank, investment }

extension AccountTypeLabel on AccountType {
  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank';
      case AccountType.investment:
        return 'Investment';
    }
  }
}

/// A place money lives. The current balance is never stored: it is derived as
/// [openingBalance] + credits - debits, so edits and deletes can never drift.
class AccountModel {
  const AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.createdAt,
    this.provider,
    this.last4,
  });

  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double openingBalance;
  final DateTime createdAt;
  final String? provider;
  final String? last4;

  AccountModel copyWith({String? name, double? openingBalance, String? provider, String? last4}) {
    return AccountModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type,
      openingBalance: openingBalance ?? this.openingBalance,
      createdAt: createdAt,
      provider: provider ?? this.provider,
      last4: last4 ?? this.last4,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'name': name,
        'type': type.name,
        'openingBalance': openingBalance,
        'createdAt': createdAt.toIso8601String(),
        'provider': provider,
        'last4': last4,
      };

  static AccountModel? tryFromMap(dynamic raw) {
    final r = MapReader.from(raw);
    if (r == null) return null;
    final id = r.str('id');
    final userId = r.str('userId');
    if (id == null || userId == null) return null;
    final typeName = r.strOr('type', 'bank');
    final type = AccountType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => AccountType.bank,
    );
    return AccountModel(
      id: id,
      userId: userId,
      name: r.strOr('name', 'Account'),
      type: type,
      openingBalance: r.dbl('openingBalance'),
      createdAt: r.date('createdAt') ?? DateTime.now(),
      provider: r.str('provider'),
      last4: r.str('last4'),
    );
  }
}
