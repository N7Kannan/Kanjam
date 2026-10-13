import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/splash/splash_screen.dart';
import 'services/account_service.dart';
import 'services/app_services.dart';
import 'services/auth_service.dart';
import 'services/budget_service.dart';
import 'services/finance_coordinator.dart';
import 'services/goal_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';
import 'services/transaction_service.dart';

/// Opens storage while the splash screen is showing, then starts the app.
/// If startup fails the user gets a retry screen, not a crash.
class KanjamBootstrap extends StatefulWidget {
  const KanjamBootstrap({super.key});

  @override
  State<KanjamBootstrap> createState() => _KanjamBootstrapState();
}

class _KanjamBootstrapState extends State<KanjamBootstrap> {
  late Future<AppServices> _future = _load();

  Future<AppServices> _load() async {
    final started = DateTime.now();
    final services = await AppServices.create();
    final elapsed = DateTime.now().difference(started);
    if (elapsed < AppConstants.splashMinDuration) {
      await Future<void>.delayed(AppConstants.splashMinDuration - elapsed);
    }
    return services;
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices>(
      future: _future,
      builder: (context, snapshot) {
        final services = snapshot.data;
        if (services != null) return KanjamApp(services: services);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.dark,
          home: snapshot.hasError
              ? _StartupError(error: snapshot.error, onRetry: _retry)
              : const SplashScreen(),
        );
      },
    );
  }
}

class KanjamApp extends StatelessWidget {
  const KanjamApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: services.storage),
        ChangeNotifierProvider<AuthService>.value(value: services.auth),
        ChangeNotifierProvider<SettingsService>.value(value: services.settings),
        ChangeNotifierProvider<AccountService>.value(value: services.accounts),
        ChangeNotifierProvider<TransactionService>.value(value: services.transactions),
        ChangeNotifierProvider<BudgetService>.value(value: services.budgets),
        ChangeNotifierProvider<GoalService>.value(value: services.goals),
        ChangeNotifierProvider<NotificationService>.value(value: services.notifications),
        Provider<FinanceCoordinator>.value(value: services.coordinator),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.error_outline, size: 54, color: p.debit),
                const SizedBox(height: 16),
                Text(
                  'KANJAM could not start',
                  style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your data is safe. Please try again. If this keeps happening, '
                  'restart the app or your phone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
