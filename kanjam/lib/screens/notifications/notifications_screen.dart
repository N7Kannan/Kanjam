import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';
import '../../widgets/common.dart';

/// In-app notification centre: budget alerts, goal updates and transactions.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;

  IconData _iconFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.budget:
        return Icons.pie_chart_outline;
      case NotificationKind.goal:
        return Icons.flag_outlined;
      case NotificationKind.transaction:
        return Icons.swap_horiz;
      case NotificationKind.system:
        return Icons.info_outline;
    }
  }

  Color _colorFor(AppPalette p, NotificationItem n) {
    switch (n.kind) {
      case NotificationKind.budget:
        return n.title.contains('Exceeded') ? p.debit : p.warning;
      case NotificationKind.goal:
        return p.credit;
      case NotificationKind.transaction:
        return n.title.startsWith('Credit') ? p.credit : p.debit;
      case NotificationKind.system:
        return p.textSecondary;
    }
  }

  Future<void> _clearAll(NotificationService service) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Clear all notifications?',
      message: 'This removes every notification. It cannot be undone.',
      confirmLabel: 'Clear all',
      destructive: true,
    );
    if (ok) await service.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final service = context.watch<NotificationService>();
    final all = service.items;
    final unread = all.where((n) => !n.isRead).toList();
    final shown = _unreadOnly ? unread : all;

    return Scaffold(
      appBar: KAppBar(
        title: 'Notifications',
        actions: <Widget>[
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: unread.isEmpty ? null : service.markAllRead,
          ),
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: all.isEmpty ? null : () => _clearAll(service),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FilterPill(
                    label: 'All (${all.length})',
                    selected: !_unreadOnly,
                    onTap: () => setState(() => _unreadOnly = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterPill(
                    label: 'Unread (${unread.length})',
                    selected: _unreadOnly,
                    onTap: () => setState(() => _unreadOnly = true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? SingleChildScrollView(
                    child: Center(
                      child: EmptyState(
                        icon: Icons.notifications_none,
                        title: _unreadOnly ? 'No unread notifications' : 'No notifications yet',
                        message: _unreadOnly
                            ? null
                            : 'Budget alerts, goal updates and new transactions will appear here.',
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: shown.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = shown[index];
                      final color = _colorFor(p, n);
                      return Dismissible(
                        key: ValueKey<String>(n.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => service.remove(n.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: p.debit,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        child: AppCard(
                          onTap: () => service.markRead(n.id),
                          borderColor: n.isRead ? null : color.withValues(alpha: 0.5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_iconFor(n.kind), color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: TextStyle(
                                              color: p.textPrimary,
                                              fontWeight:
                                                  n.isRead ? FontWeight.w600 : FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        if (!n.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: p.accent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      n.message,
                                      style: TextStyle(
                                        color: p.textSecondary,
                                        fontSize: 13.5,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      Fmt.relative(n.createdAt),
                                      style: TextStyle(color: p.textMuted, fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
