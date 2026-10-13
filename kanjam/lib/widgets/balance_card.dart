import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';

/// Total balance with the cash / bank / investment split.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.total,
    required this.cash,
    required this.bank,
    required this.investment,
  });

  final double total;
  final double cash;
  final double bank;
  final double investment;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.accent.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[p.accent.withValues(alpha: 0.20), p.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Total Balance', style: TextStyle(color: p.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.money(total),
              style: TextStyle(
                color: total < 0 ? p.debit : p.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: _Part(label: 'Cash', value: cash, icon: Icons.payments_outlined)),
              Expanded(child: _Part(label: 'Bank', value: bank, icon: Icons.account_balance_outlined)),
              Expanded(
                child: _Part(label: 'Invested', value: investment, icon: Icons.trending_up),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({required this.label, required this.value, required this.icon});

  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 14, color: p.textMuted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Fmt.money(value, decimals: false),
            style: TextStyle(
              color: value < 0 ? p.debit : p.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
