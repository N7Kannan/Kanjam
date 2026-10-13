import 'package:flutter/material.dart';

import '../core/categories.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../services/finance_calculator.dart';
import 'category_badge.dart';
import 'common.dart';

/// One budget: spent vs limit, a progress bar and its alert state.
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.status, this.onTap});

  final BudgetStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final level = status.level;
    final barColor = switch (level) {
      BudgetLevel.ok => p.accent,
      BudgetLevel.warning => p.warning,
      BudgetLevel.reached => p.warning,
      BudgetLevel.exceeded => p.debit,
    };
    final name = status.budget.category == Categories.overall
        ? 'Overall spending'
        : status.budget.category;

    String? badge;
    if (level == BudgetLevel.exceeded) {
      badge = '100% EXCEEDED';
    } else if (level == BudgetLevel.reached) {
      badge = 'LIMIT REACHED';
    } else if (level == BudgetLevel.warning) {
      badge = '80% ALERT';
    }

    final String footer = status.remaining >= 0
        ? '${Fmt.money(status.remaining)} left'
        : 'Over by ${Fmt.money(-status.remaining)}';

    return AppCard(
      onTap: onTap,
      borderColor: level == BudgetLevel.exceeded ? p.debit.withValues(alpha: 0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CategoryBadge(category: status.budget.category, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Fmt.money(status.spent)} of ${Fmt.money(status.limit)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Text(
                Fmt.percent(status.ratio),
                style: TextStyle(color: barColor, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: status.barValue,
              minHeight: 8,
              backgroundColor: p.surfaceAlt,
              color: barColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  footer,
                  style: TextStyle(
                    color: level == BudgetLevel.exceeded ? p.debit : p.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: barColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
