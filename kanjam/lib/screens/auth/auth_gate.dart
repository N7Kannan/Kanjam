import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common.dart';
import '../home/home_shell.dart';
import '../lock/lock_screen.dart';
import '../onboarding/onboarding_flow.dart';
import 'login_screen.dart';

/// Chooses what to show from saved state alone: sign-in, the next unfinished
/// onboarding step, the PIN lock, or the app. Because the choice is derived
/// (not pushed), login, logout and restart can never leave navigation stale.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageService>();
    if (storage.recoveredFromCorruption) {
      storage.recoveredFromCorruption = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showAppSnack(
          context,
          'Some saved data could not be read and was reset.',
          error: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    if (user == null) return const LoginScreen();
    if (!user.onboardingComplete) return const OnboardingFlow();
    if (auth.isLocked) return const LockScreen();
    return const HomeShell();
  }
}
