import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/common.dart';
import '../../widgets/kanjam_logo.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthService>();
    final ok = await showConfirmDialog(
      context,
      title: 'Log out',
      message: 'Are you sure you want to log out from KANJAM?',
      confirmLabel: 'LOG OUT',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    // Close anything stacked on top so nothing stale remains after sign-out.
    Navigator.of(context).popUntil((route) => route.isFirst);
    await auth.logout();
  }

  void _showHelp(BuildContext context) {
    showKSheet<void>(context, (ctx) {
      final p = ctx.pal;
      Widget item(IconData icon, String title, String body) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(icon, color: p.accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(body, style: TextStyle(color: p.textSecondary, height: 1.35, fontSize: 13.5)),
                    ],
                  ),
                ),
              ],
            ),
          );
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Help',
            style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          item(
            Icons.swap_vert,
            'Credit and debit',
            'Credit is money coming in, debit is money going out. Each one is recorded against an account, and that account\'s balance updates straight away.',
          ),
          item(
            Icons.account_balance_wallet_outlined,
            'Accounts',
            'Cash, bank and investment accounts are tracked from your own entries. KANJAM does not connect to your bank.',
          ),
          item(
            Icons.pie_chart_outline,
            'Budgets',
            'Set a monthly limit per category. Progress resets each month and you get an alert at 80% and 100%.',
          ),
          item(
            Icons.flag_outlined,
            'Goals',
            'Goal savings are tracked separately. Adding money to a goal does not change your account balances.',
          ),
          item(
            Icons.lock_outline,
            'Privacy',
            'Everything is stored on this device only. Turn on App Lock in Settings to protect it with a PIN.',
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final user = context.watch<AuthService>().user;
    final unread = context.watch<NotificationService>().unreadCount;
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
      appBar: const KAppBar(title: 'Profile', showBack: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: <Widget>[
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 30,
                  backgroundColor: p.accent,
                  child: Text(
                    user.initial,
                    style: TextStyle(
                      color: p.onAccent,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user.name.isEmpty ? 'Your name' : user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.loginId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.textSecondary),
                      ),
                      if (user.monthlyIncome > 0)
                        Text(
                          'Monthly income ${Fmt.money(user.monthlyIncome, decimals: false)}',
                          style: TextStyle(color: p.textMuted, fontSize: 12.5),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          group('ACCOUNT & PREFERENCES', <Widget>[
            SettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Name, income, contact details',
              onTap: () => showKSheet<void>(context, (_) => const _EditProfileSheet()),
            ),
            SettingsTile(
              icon: Icons.lock_reset,
              title: 'Change Password',
              subtitle: 'Update your sign-in password',
              onTap: () => showKSheet<void>(context, (_) => const _ChangePasswordSheet()),
            ),
            SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: unread > 0 ? '$unread unread' : 'Budget alerts, goal updates, transactions',
              onTap: () => pushOnce<void>(context, const NotificationsScreen()),
            ),
            SettingsTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Appearance, alerts, app lock, data',
              onTap: () => pushOnce<void>(context, const SettingsScreen()),
            ),
          ]),
          group('SUPPORT', <Widget>[
            SettingsTile(
              icon: Icons.help_outline,
              title: 'Help',
              subtitle: 'How credits, budgets and goals work',
              onTap: () => _showHelp(context),
            ),
            SettingsTile(
              icon: Icons.info_outline,
              title: 'About KANJAM',
              subtitle: 'Version ${AppConstants.appVersion} (Build ${AppConstants.appBuild})',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: '${AppConstants.appVersion} (Build ${AppConstants.appBuild})',
                applicationIcon: const KanjamLogo(size: 48),
                children: <Widget>[
                  const SizedBox(height: 8),
                  const Text(
                    '${AppConstants.tagline}. A simple, private money tracker. '
                    'Your data stays on this device.',
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'LOG OUT',
            icon: Icons.logout,
            danger: true,
            outlined: true,
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _income;
  late final TextEditingController _contact;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthService>().user;
    _name = TextEditingController(text: u?.name ?? '');
    final income = u?.monthlyIncome ?? 0;
    _income = TextEditingController(
      text: income == 0 ? '0' : income.toStringAsFixed(income % 1 == 0 ? 0 : 2),
    );
    _contact = TextEditingController(text: u?.contact ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _income.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await auth.updateProfile(
        name: _name.text,
        monthlyIncome: AmountParser.tryParse(_income.text) ?? 0,
        contact: _contact.text,
      );
      if (!mounted) return;
      showAppSnack(context, 'Profile updated');
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppSnack(context, 'Could not save. Please try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Edit Profile',
            style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          KTextField(
            controller: _name,
            label: 'Your Name',
            icon: Icons.person_outline,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: Validators.name,
          ),
          const SizedBox(height: 14),
          AmountField(
            controller: _income,
            label: 'Monthly income',
            textInputAction: TextInputAction.next,
            validator: (v) =>
                Validators.amount(v, allowZero: true, emptyMessage: 'Please enter monthly income'),
          ),
          const SizedBox(height: 14),
          KTextField(
            controller: _contact,
            label: 'Recovery email or phone',
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.contact,
          ),
          const SizedBox(height: 18),
          PrimaryButton(label: 'SAVE CHANGES', loading: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await auth.changePassword(_current.text, _next.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    showAppSnack(context, 'Password updated successfully');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Change Password',
            style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _current,
            label: 'Current Password',
            validator: Validators.loginPassword,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          PasswordField(
            controller: _next,
            label: 'New Password',
            validator: Validators.password,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          PasswordField(
            controller: _confirm,
            label: 'Confirm New Password',
            validator: (v) => Validators.confirmPassword(v, _next.text),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: p.debit)),
            ),
          const SizedBox(height: 18),
          PrimaryButton(label: 'UPDATE PASSWORD', loading: _busy, onPressed: _save),
        ],
      ),
    );
  }
}
