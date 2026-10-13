import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/cyber_wave.dart';
import '../../widgets/kanjam_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child: const SafeArea(child: CyberWave(height: 140)),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) => Opacity(opacity: value, child: child),
              child: const KanjamLogo(size: 120, showWordmark: true),
            ),
          ),
        ],
      ),
    );
  }
}
