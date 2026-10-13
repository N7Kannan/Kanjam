import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/budget_service.dart';
import '../../services/finance_coordinator.dart';
import '../../services/goal_service.dart';
import '../../services/settings_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pin_pad.dart';

/// Appearance, in-app alerts, App Lock and data controls. Every row here
/// changes real state; nothing is decorative.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark (Fintech Black & green)';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'Follow system setting';
    }
  }

  void _chooseTheme(BuildContext context) {
    final settings = context.read<SettingsService>();
    showKSheet<void>(context, (ctx) {
      final p = ctx.pal;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Appearance',
            style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final mode in ThemeMode.values)
            SettingsTile(
              icon: switch (mode) {
                ThemeMode.dark => Icons.dark_mode_outlined,
                ThemeMode.light => Icons.light_mode_outlined,
                ThemeMode.system => Icons.brightness_auto_outlined,
              },
              title: _themeLabel(mode),
              trailing: settings.themeMode == mode
                  ? Icon(Icons.check_circle, color: p.accent)
                  : Icon(Icons.circle_outlined, color: p.textMuted),
              onTap: () {
                settings.setThemeMode(mode);
                Navigator.of(ctx).pop();
              },
            ),
        ],
      );
    });
  }

  Future<void> _toggleLock(BuildContext context, bool enable) async {
    final ok = await showKSheet<bool>(
      context,
      (ctx) => enable ? const _PinSetupSheet() : const _PinVerifySheet(),
    );
    if (ok == true && context.mounted) {
      showAppSnack(context, enable ? 'App Lock turned on' : 'App Lock turned off');
    }
  }

  Future<void> _erase(BuildContext context) async {
    final coordinator = context.read<FinanceCoordinator>();
    final ok = await showConfirmDialog(
      context,
      title: 'Erase my data?',
      message: 'This permanently deletes all your transactions, budgets, goals and '
          'notifications. Your accounts and their opening balances are kept. '
          'This cannot be undone.',
      confirmLabel: 'Erase',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await coordinator.eraseUserData();
      if (context.mounted) showAppSnack(context, 'Your data has been erased');
    } catch (_) {
      if (context.mounted) {
        showAppSnack(context, 'Could not erase data. Please try again.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final settings = context.watch<SettingsService>();
    final user = context.watch<AuthService>().user;
    final txCount = context.watch<TransactionService>().all.length;
    final budgetCount = context.watch<BudgetService>().budgets.length;
    final goalCount = context.watch<GoalService>().goals.length;
    if (user == null) return const SizedBox.shrink();

    Widget group(String title, List<Widget> tiles) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8, top: 18),
              child: Text(
                title,
                style: TextStyle(
                  color: p.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: <Widget>[
                  for (var i = 0; i < tiles.length; i++) ...<Widget>[
                    if (i > 0) Divider(height: 1, color: p.border),
                    tiles[i],
                  ],
                ],
              ),
            ),
          ],
        );

    return Scaffold(
      appBar: const KAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: <Widget>[
          group('PREFERENCES', <Widget>[
            SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: _themeLabel(settings.themeMode),
              onTap: () => _chooseTheme(context),
            ),
            SettingsTile(
              icon: Icons.notifications_active_outlined,
              title: 'In-App Notifications',
              subtitle: 'Budget alerts, goal updates, transactions',
              trailing: Switch(
                value: user.notificationsEnabled,
                onChanged: (v) => context.read<AuthService>().setNotificationsEnabled(v),
              ),
              onTap: () => context
                  .read<AuthService>()
                  .setNotificationsEnabled(!user.notificationsEnabled),
            ),
            SettingsTile(
              icon: Icons.pin_outlined,
              title: 'App Lock',
              subtitle: user.lockEnabled
                  ? 'A ${AppConstants.pinLength}-digit PIN is required when KANJAM opens'
                  : 'Require a ${AppConstants.pinLength}-digit PIN when KANJAM opens',
              trailing: Switch(
                value: user.lockEnabled,
                onChanged: (v) => _toggleLock(context, v),
              ),
              onTap: () => _toggleLock(context, !user.lockEnabled),
            ),
          ]),
          group('DATA', <Widget>[
            SettingsTile(
              icon: Icons.storage_outlined,
              title: 'Local storage',
              subtitle: 'On-device database (Hive): $txCount transactions, '
                  '$budgetCount budgets, $goalCount goals',
            ),
            SettingsTile(
              icon: Icons.delete_forever_outlined,
              title: 'Erase my data',
              subtitle: 'Delete transactions, budgets, goals and notifications. Accounts stay.',
              danger: true,
              onTap: () => _erase(context),
            ),
          ]),
          group('ABOUT', <Widget>[
            const SettingsTile(
              icon: Icons.info_outline,
              title: 'Application Version',
              subtitle: '${AppConstants.appVersion} (Build ${AppConstants.appBuild})',
            ),
            const SettingsTile(
              icon: Icons.verified_user_outlined,
              title: 'Data Protection Guarantee',
              subtitle: 'Your data is stored only on this device. KANJAM never uploads or shares it.',
            ),
          ]),
        ],
      ),
    );
  }
}

/// Choose a PIN, then enter it again to confirm.
class _PinSetupSheet extends StatefulWidget {
  const _PinSetupSheet();

  @override
  State<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<_PinSetupSheet> {
  String _value = '';
  String _first = '';
  bool _confirming = false;
  bool _busy = false;
  String? _error;

  Future<void> _onChanged(String v) async {
    if (_busy) return;
    setState(() {
      _value = v;
      _error = null;
    });
    if (v.length != AppConstants.pinLength) return;

    if (!_confirming) {
      setState(() {
        _first = v;
        _value = '';
        _confirming = true;
      });
      return;
    }
    if (v != _first) {
      setState(() {
        _value = '';
        _first = '';
        _confirming = false;
        _error = 'The PINs did not match. Start again.';
      });
      return;
    }
    final auth = context.read<AuthService>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    await auth.setPin(v);
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          _confirming ? 'Confirm your PIN' : 'Choose a PIN',
          style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          _confirming
              ? 'Enter the same ${AppConstants.pinLength} digits again.'
              : 'Pick ${AppConstants.pinLength} digits you will remember.',
          style: TextStyle(color: p.textSecondary),
        ),
        const SizedBox(height: 20),
        PinDots(length: AppConstants.pinLength, filled: _value.length, error: _error != null),
        SizedBox(
          height: 30,
          child: _error == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: p.debit)),
                ),
        ),
        const SizedBox(height: 8),
        PinPad(value: _value, length: AppConstants.pinLength, onChanged: _onChanged),
      ],
    );
  }
}

/// Enter the current PIN to turn App Lock off.
class _PinVerifySheet extends StatefulWidget {
  const _PinVerifySheet();

  @override
  State<_PinVerifySheet> createState() => _PinVerifySheetState();
}

class _PinVerifySheetState extends State<_PinVerifySheet> {
  String _value = '';
  bool _wrong = false;
  bool _busy = false;

  Future<void> _onChanged(String v) async {
    if (_busy) return;
    setState(() {
      _value = v;
      _wrong = false;
    });
    if (v.length != AppConstants.pinLength) return;

    final auth = context.read<AuthService>();
    final navigator = Navigator.of(context);
    if (auth.verifyPin(v)) {
      setState(() => _busy = true);
      await auth.clearPin();
      navigator.pop(true);
    } else {
      setState(() {
        _value = '';
        _wrong = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Turn off App Lock',
          style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text('Enter your current PIN.', style: TextStyle(color: p.textSecondary)),
        const SizedBox(height: 20),
        PinDots(length: AppConstants.pinLength, filled: _value.length, error: _wrong),
        SizedBox(
          height: 30,
          child: _wrong
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Incorrect PIN', style: TextStyle(color: p.debit)),
                )
              : null,
        ),
        const SizedBox(height: 8),
        PinPad(value: _value, length: AppConstants.pinLength, onChanged: _onChanged),
      ],
    );
  }
}
