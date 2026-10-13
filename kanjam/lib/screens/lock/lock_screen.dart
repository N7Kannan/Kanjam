import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import '../../widgets/kanjam_logo.dart';
import '../../widgets/pin_pad.dart';

/// Shown at launch when the user has turned on App Lock.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  bool _wrong = false;

  void _onChanged(String value) {
    setState(() {
      _pin = value;
      _wrong = false;
    });
    if (value.length == AppConstants.pinLength) _verify(value);
  }

  void _verify(String value) {
    final ok = context.read<AuthService>().unlockWithPin(value);
    // On success the AuthGate replaces this screen.
    if (!ok && mounted) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() {
        _pin = '';
        _wrong = true;
      });
    }
  }

  Future<void> _forgotPin() async {
    final auth = context.read<AuthService>();
    final controller = TextEditingController();
    final p = context.pal;
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Forgot PIN?', style: TextStyle(color: p.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Enter your account password to turn off App Lock.',
              style: TextStyle(color: p.textSecondary),
            ),
            const SizedBox(height: 12),
            PasswordField(controller: controller, label: 'Password', autofocus: true),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty) return;
    final ok = await auth.unlockWithPassword(password);
    if (!ok && mounted) showAppSnack(context, 'Incorrect password', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const KanjamLogo(size: 72),
                const SizedBox(height: 20),
                Text(
                  'Enter your PIN',
                  style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                PinDots(length: AppConstants.pinLength, filled: _pin.length, error: _wrong),
                SizedBox(
                  height: 28,
                  child: _wrong
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Incorrect PIN', style: TextStyle(color: p.debit)),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                PinPad(value: _pin, length: AppConstants.pinLength, onChanged: _onChanged),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _forgotPin,
                  style: TextButton.styleFrom(foregroundColor: p.accent),
                  child: const Text('Forgot PIN?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
