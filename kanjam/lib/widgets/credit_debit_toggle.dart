import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Two-way switch between money coming in (credit) and going out (debit).
class CreditDebitToggle extends StatelessWidget {
  const CreditDebitToggle({super.key, required this.isCredit, required this.onChanged});

  final bool isCredit;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _Segment(
              label: 'Credit',
              icon: Icons.south_west,
              selected: isCredit,
              color: p.credit,
              onColor: p.onAccent,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _Segment(
              label: 'Debit',
              icon: Icons.north_east,
              selected: !isCredit,
              color: p.debit,
              onColor: Colors.white,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: selected ? onColor : p.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? onColor : p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
