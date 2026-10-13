import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';

/// The KANJAM wallet mark, optionally with the wordmark and tagline.
/// Falls back to a drawn wallet icon if the asset cannot be loaded.
class KanjamLogo extends StatelessWidget {
  const KanjamLogo({super.key, this.size = 96, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final mark = Image.asset(
      'assets/images/logo_mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(size * 0.22),
        ),
        child: Icon(Icons.account_balance_wallet, size: size * 0.55, color: p.onAccent),
      ),
    );
    if (!showWordmark) {
      return Semantics(label: '${AppConstants.appName} logo', child: mark);
    }
    return Semantics(
      label: '${AppConstants.appName}. ${AppConstants.tagline}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          mark,
          SizedBox(height: size * 0.14),
          Text(
            AppConstants.appName,
            style: TextStyle(
              color: p.accent,
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
              letterSpacing: size * 0.06,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.tagline,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: math.max(12, size * 0.13),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
