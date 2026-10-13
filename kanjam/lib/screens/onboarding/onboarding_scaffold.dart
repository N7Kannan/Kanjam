import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import '../../widgets/onboarding_indicator.dart';

/// Shared layout for the five onboarding screens: progress bars, title,
/// scrollable content and a pinned Continue button that stays above the keyboard.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onContinue,
    this.continueLabel = 'CONTINUE',
    this.busy = false,
    this.onSkip,
    this.footer = 'Your data is stored only on this device.',
  });

  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onContinue;
  final String continueLabel;
  final bool busy;
  final VoidCallback? onSkip;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: step > 0
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: busy
                    ? null
                    : () => unawaited(auth.saveOnboardingProgress(nextStep: step - 1)),
              )
            : null,
        actions: <Widget>[
          if (step == 0)
            TextButton(
              onPressed: busy ? null : () => unawaited(auth.logout()),
              style: TextButton.styleFrom(foregroundColor: p.textSecondary),
              child: const Text('Sign out'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    OnboardingStepIndicator(current: step, total: totalSteps),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(subtitle, style: TextStyle(color: p.textSecondary, height: 1.4)),
                    const SizedBox(height: 24),
                    child,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  PrimaryButton(label: continueLabel, loading: busy, onPressed: onContinue),
                  if (onSkip != null)
                    TextButton(
                      onPressed: busy ? null : onSkip,
                      style: TextButton.styleFrom(foregroundColor: p.textSecondary),
                      child: const Text('Skip for now'),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.lock_outline, size: 14, color: p.textMuted),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          footer,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
