/// App-wide constants. Nothing in here is user data.
class AppConstants {
  AppConstants._();

  static const String appName = 'KANJAM';
  static const String tagline = 'Every Rupee Counts';

  /// Keep in sync with `version:` in pubspec.yaml.
  static const String appVersion = '1.1.0';
  static const String appBuild = '2';

  static const String currencySymbol = '\u20B9'; // Rupee sign

  /// Largest single amount accepted anywhere in the app (about 999 crore).
  static const double maxAmount = 9999999999.99;

  static const int minUserIdLength = 3;
  static const int minPasswordLength = 6;
  static const int pinLength = 4;

  static const int maxNotifications = 200;
  static const double budgetWarnRatio = 0.8;

  static const Duration splashMinDuration = Duration(milliseconds: 900);

  // Hive boxes. "v2" keeps the rebuilt app away from the old APK's boxes,
  // whose schema cannot be recovered from a release build.
  static const String usersBox = 'kanjam_v2_users';
  static const String accountsBox = 'kanjam_v2_accounts';
  static const String transactionsBox = 'kanjam_v2_transactions';
  static const String budgetsBox = 'kanjam_v2_budgets';
  static const String goalsBox = 'kanjam_v2_goals';
  static const String notificationsBox = 'kanjam_v2_notifications';
  static const String settingsBox = 'kanjam_v2_settings';

  // Keys inside the settings box.
  static const String keyCurrentUser = 'current_user';
  static const String keyThemeMode = 'theme_mode';
  static const String keySchemaVersion = 'schema_version';
  static const int schemaVersion = 2;

  static const List<String> bankProviders = <String>[
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Punjab National Bank',
    'India Post Payments Bank',
    'Other bank',
  ];

  static const List<String> investmentTypes = <String>[
    'Mutual Funds & Stocks',
    'Gold',
    'Other',
  ];

  static const List<String> incomeSources = <String>[
    'Salary',
    'Freelance',
    'Allowance',
    'Business',
    'Other',
  ];

  static const List<String> paymentModes = <String>[
    'UPI',
    'Cash',
    'Card',
    'Bank Transfer',
    'Other',
  ];
}
