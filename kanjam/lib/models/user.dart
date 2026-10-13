import 'map_reader.dart';

/// A local KANJAM profile. Passwords and PINs are stored only as salted hashes.
class UserModel {
  const UserModel({
    required this.id,
    required this.loginId,
    required this.name,
    required this.passwordHash,
    required this.salt,
    required this.contact,
    required this.createdAt,
    this.monthlyIncome = 0,
    this.incomeSource = 'Salary',
    this.onboardingStep = 0,
    this.onboardingComplete = false,
    this.onboardingDraft = const <String, dynamic>{},
    this.notificationsEnabled = true,
    this.pinHash,
    this.pinSalt,
  });

  /// Normalised (trimmed, lower-case) login id; also the storage key.
  final String id;
  final String loginId;
  final String name;
  final String passwordHash;
  final String salt;

  /// Recovery email or phone, normalised.
  final String contact;
  final DateTime createdAt;
  final double monthlyIncome;
  final String incomeSource;

  /// Index of the next onboarding screen to show (0 = name ... 4 = investments).
  final int onboardingStep;
  final bool onboardingComplete;

  /// Answers collected during onboarding, applied when onboarding finishes.
  final Map<String, dynamic> onboardingDraft;
  final bool notificationsEnabled;
  final String? pinHash;
  final String? pinSalt;

  bool get lockEnabled => pinHash != null && pinSalt != null;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'there' : parts.first;
  }

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  UserModel copyWith({
    String? name,
    String? passwordHash,
    String? salt,
    String? contact,
    double? monthlyIncome,
    String? incomeSource,
    int? onboardingStep,
    bool? onboardingComplete,
    Map<String, dynamic>? onboardingDraft,
    bool? notificationsEnabled,
    String? pinHash,
    String? pinSalt,
    bool clearPin = false,
  }) {
    return UserModel(
      id: id,
      loginId: loginId,
      name: name ?? this.name,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      contact: contact ?? this.contact,
      createdAt: createdAt,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      incomeSource: incomeSource ?? this.incomeSource,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      onboardingDraft: onboardingDraft ?? this.onboardingDraft,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pinHash: clearPin ? null : (pinHash ?? this.pinHash),
      pinSalt: clearPin ? null : (pinSalt ?? this.pinSalt),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'loginId': loginId,
        'name': name,
        'passwordHash': passwordHash,
        'salt': salt,
        'contact': contact,
        'createdAt': createdAt.toIso8601String(),
        'monthlyIncome': monthlyIncome,
        'incomeSource': incomeSource,
        'onboardingStep': onboardingStep,
        'onboardingComplete': onboardingComplete,
        'onboardingDraft': onboardingDraft,
        'notificationsEnabled': notificationsEnabled,
        'pinHash': pinHash,
        'pinSalt': pinSalt,
      };

  static int _boundedStep(int v) => v < 0 ? 0 : (v > 5 ? 5 : v);

  /// Returns null when the record is unusable (so one bad record cannot crash
  /// the app or block everyone else from logging in).
  static UserModel? tryFromMap(dynamic raw) {
    final r = MapReader.from(raw);
    if (r == null) return null;
    final id = r.str('id');
    final hash = r.str('passwordHash');
    final salt = r.str('salt');
    if (id == null || hash == null || salt == null) return null;
    return UserModel(
      id: id,
      loginId: r.strOr('loginId', id),
      name: r.strOr('name', ''),
      passwordHash: hash,
      salt: salt,
      contact: r.strOr('contact', ''),
      createdAt: r.date('createdAt') ?? DateTime.now(),
      monthlyIncome: r.dbl('monthlyIncome'),
      incomeSource: r.strOr('incomeSource', 'Salary'),
      onboardingStep: _boundedStep(r.integer('onboardingStep')),
      onboardingComplete: r.boolean('onboardingComplete'),
      onboardingDraft: r.map('onboardingDraft'),
      notificationsEnabled: r.boolean('notificationsEnabled', true),
      pinHash: r.str('pinHash'),
      pinSalt: r.str('pinSalt'),
    );
  }
}
