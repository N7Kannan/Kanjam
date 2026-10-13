import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await auth.signUp(
      loginId: _idController.text,
      password: _passwordController.text,
      contact: _contactController.text,
    );
    if (!mounted) return;
    if (error == null) {
      // The AuthGate underneath now shows onboarding; remove this screen.
      navigator.pop();
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
    return Scaffold(
      appBar: const KAppBar(title: ''),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Create Your Account',
                  style: TextStyle(color: p.textPrimary, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your data stays on this device.',
                  style: TextStyle(color: p.textSecondary),
                ),
                const SizedBox(height: 24),
                KTextField(
                  controller: _idController,
                  label: 'User ID or Email',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.userId,
                ),
                const SizedBox(height: 14),
                KTextField(
                  controller: _contactController,
                  label: 'Recovery email or phone',
                  hint: 'Used if you forget your password',
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.contact,
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _confirmController,
                  label: 'Confirm Password',
                  validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.error_outline, size: 18, color: p.debit),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: TextStyle(color: p.debit))),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'CREATE ACCOUNT', loading: _busy, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
