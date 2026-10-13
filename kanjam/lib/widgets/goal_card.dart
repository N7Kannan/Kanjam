import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/goal.dart';
import 'common.dart';

enum GoalMenuAction { edit, delete }

/// A savings goal with progress, an "Add money" action and an edit/delete menu.
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    this.onAddMoney,
    this.onMenu,
    this.compact = false,
  });

  final GoalModel goal;
  final VoidCallback? onAddMoney;
  final ValueChanged<GoalMenuAction>? onMenu;

  /// Home-screen variant: no actions.
  final bool compact;

  String _deadlineText(DateTime now) {
    final target = goal.targetDate;
    if (goal.isCompleted) return 'Goal reached';
    if (target == null) return '${Fmt.money(goal.remaining)} to go';
    final today = DateTime(now.year, now.month, now.day);
    final days = DateTime(target.year, target.month, target.day).difference(today).inDays;
    if (days < 0) return '${Fmt.money(goal.remaining)} to go - overdue';
    if (days == 0) return '${Fmt.money(goal.remaining)} to go - due today';
    return '${Fmt.money(goal.remaining)} to go - $days day${days == 1 ? '' : 's'} left';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final done = goal.isCompleted;
    final color = done ? p.credit : p.accent;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(done ? Icons.emoji_events : Icons.flag, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      goal.name,
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
                      '${Fmt.money(goal.currentAmount)} of ${Fmt.money(goal.targetAmount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Text(
                Fmt.percent(goal.progress),
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              if (!compact && onMenu != null)
                PopupMenuButton<GoalMenuAction>(
                  tooltip: 'Goal options',
                  color: p.surface,
                  icon: Icon(Icons.more_vert, color: p.textSecondary),
                  onSelected: onMenu,
                  itemBuilder: (ctx) => <PopupMenuEntry<GoalMenuAction>>[
                    PopupMenuItem<GoalMenuAction>(
                      value: GoalMenuAction.edit,
                      child: Text('Edit', style: TextStyle(color: p.textPrimary)),
                    ),
                    PopupMenuItem<GoalMenuAction>(
                      value: GoalMenuAction.delete,
                      child: Text('Delete', style: TextStyle(color: p.debit)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: p.surfaceAlt,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _deadlineText(DateTime.now()),
                  style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                ),
              ),
              if (!compact && !done && onAddMoney != null)
                TextButton.icon(
                  onPressed: onAddMoney,
                  style: TextButton.styleFrom(foregroundColor: p.accent),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add money'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
