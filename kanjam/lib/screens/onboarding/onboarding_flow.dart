import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import 'bank_screen.dart';
import 'cash_screen.dart';
import 'income_screen.dart';
import 'investment_screen.dart';
import 'name_screen.dart';

/// Shows the onboarding screen for the step saved on the user's profile
/// (name, income, cash, bank, investments). Every step saves on Continue, so
/// closing the app mid-way resumes at the right screen with answers intact.
class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  static const int totalSteps = 5;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();
    final saved = user.onboardingStep;
    final step = saved < 0 ? 0 : (saved > totalSteps - 1 ? totalSteps - 1 : saved);

    final Widget screen;
    switch (step) {
      case 0:
        screen = const NameScreen(key: ValueKey<int>(0));
      case 1:
        screen = const IncomeScreen(key: ValueKey<int>(1));
      case 2:
        screen = const CashScreen(key: ValueKey<int>(2));
      case 3:
        screen = const BankScreen(key: ValueKey<int>(3));
      default:
        screen = const InvestmentScreen(key: ValueKey<int>(4));
    }

    // The system Back button goes to the previous step instead of leaving
    // the app. On the first step it behaves normally.
    return PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && step > 0) {
          unawaited(auth.saveOnboardingProgress(nextStep: step - 1));
        }
      },
      child: screen,
    );
  }
}
