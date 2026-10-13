import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import 'common.dart';

/// Small stat card: label, amount and an optional caption.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.caption,
    this.asPercent = false,
    this.placeholder,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final String? caption;

  /// Show [amount] as a percentage (0.25 -> 25%) instead of money.
  final bool asPercent;

  /// Shown instead of a value when there is nothing meaningful to display.
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final text = placeholder ?? (asPercent ? Fmt.percent(amount, digits: 1) : Fmt.money(amount));
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(
                color: placeholder != null ? p.textMuted : p.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.textMuted, fontSize: 11.5),
              ),
            ),
        ],
      ),
    );
  }
}
