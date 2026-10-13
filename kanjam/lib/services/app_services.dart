import 'account_service.dart';
import 'auth_service.dart';
import 'budget_service.dart';
import 'finance_coordinator.dart';
import 'goal_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';
import 'transaction_service.dart';

/// Everything the UI needs, created once after Hive is ready.
class AppServices {
  AppServices._({
    required this.storage,
    required this.auth,
    required this.settings,
    required this.accounts,
    required this.transactions,
    required this.budgets,
    required this.goals,
    required this.notifications,
    required this.coordinator,
  });

  final StorageService storage;
  final AuthService auth;
  final SettingsService settings;
  final AccountService accounts;
  final TransactionService transactions;
  final BudgetService budgets;
  final GoalService goals;
  final NotificationService notifications;
  final FinanceCoordinator coordinator;

  /// Opens storage (once) and wires the services together.
  static Future<AppServices> create() async {
    final storage = StorageService.instance;
    await storage.init();

    final auth = AuthService(storage);
    final accounts = AccountService(storage);
    final transactions = TransactionService(storage);
    final budgets = BudgetService(storage);
    final goals = GoalService(storage);
    final notifications = NotificationService(storage);

    final coordinator = FinanceCoordinator(
      auth: auth,
      accounts: accounts,
      transactions: transactions,
      budgets: budgets,
      goals: goals,
      notifications: notifications,
    );

    return AppServices._(
      storage: storage,
      auth: auth,
      settings: SettingsService(storage),
      accounts: accounts,
      transactions: transactions,
      budgets: budgets,
      goals: goals,
      notifications: notifications,
      coordinator: coordinator,
    );
  }
}
