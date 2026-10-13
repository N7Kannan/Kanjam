import 'package:flutter/material.dart';

import '../core/theme.dart';

/// "Step 2 of 5" progress bars shown on every onboarding screen.
class OnboardingStepIndicator extends StatelessWidget {
  const OnboardingStepIndicator({super.key, required this.current, required this.total});

  /// Zero-based index of the screen being shown.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      label: 'Step ${current + 1} of $total',
      child: Row(
        children: List<Widget>.generate(total, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: i <= current ? p.accent : p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
