import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cyber_wave.dart';
import '../../widgets/kanjam_logo.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await auth.login(_idController.text, _passwordController.text);
    // On success the AuthGate swaps this screen out, so there is nothing to do.
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _forgotPassword() async {
    final done = await showKSheet<bool>(
      context,
      (ctx) => _ResetPasswordSheet(initialId: _idController.text.trim()),
    );
    if (done == true && mounted) {
      showAppSnack(context, 'Password updated. Sign in with your new password.');
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Center(child: KanjamLogo(size: 88, showWordmark: true)),
                const CyberWave(height: 60),
                const SizedBox(height: 8),
                Text(
                  'Welcome back',
                  style: TextStyle(color: p.textPrimary, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to continue to your wallet',
                  style: TextStyle(color: p.textSecondary),
                ),
                const SizedBox(height: 24),
                KTextField(
                  controller: _idController,
                  label: 'User ID or Email',
                  hint: 'Enter User ID or Email',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.userId,
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  validator: Validators.loginPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _forgotPassword,
                    style: TextButton.styleFrom(foregroundColor: p.accent),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.error_outline, size: 18, color: p.debit),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: TextStyle(color: p.debit))),
                      ],
                    ),
                  ),
                PrimaryButton(label: 'SIGN IN', loading: _busy, onPressed: _submit),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('New to KANJAM?', style: TextStyle(color: p.textSecondary)),
                    TextButton(
                      onPressed: _busy ? null : () => pushOnce<void>(context, const SignupScreen()),
                      style: TextButton.styleFrom(foregroundColor: p.accent),
                      child: const Text('Create Account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Offline password reset: proves ownership with the recovery contact that was
/// saved at sign-up. (There is no server, so no recovery email can be sent.)
class _ResetPasswordSheet extends StatefulWidget {
  const _ResetPasswordSheet({required this.initialId});

  final String initialId;

  @override
  State<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<_ResetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _id = TextEditingController(text: widget.initialId);
  final _contact = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _contact.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await auth.resetPassword(
      loginId: _id.text,
      contact: _contact.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    if (error == null) {
      navigator.pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
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
            'Reset password',
            style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'KANJAM keeps your data on this device, so we cannot email a link. '
            'Enter the recovery email or phone you signed up with to choose a new password.',
            style: TextStyle(color: p.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          KTextField(
            controller: _id,
            label: 'User ID or Email',
            icon: Icons.person_outline,
            validator: Validators.userId,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          KTextField(
            controller: _contact,
            label: 'Recovery email or phone',
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.contact,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: _password,
            label: 'New password',
            validator: Validators.password,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: _confirm,
            label: 'Confirm new password',
            validator: (v) => Validators.confirmPassword(v, _password.text),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: p.debit)),
            ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'RESET PASSWORD', loading: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
