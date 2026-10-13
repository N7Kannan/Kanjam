import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/categories.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../services/finance_calculator.dart';

/// Two horizontal bars comparing income and expense. Safe with zero values.
class IncomeExpenseComparisonChart extends StatelessWidget {
  const IncomeExpenseComparisonChart({super.key, required this.income, required this.expense});

  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final maxValue = math.max(income, expense);

    Widget bar(String label, double value, Color color) {
      final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0).toDouble();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(label, style: TextStyle(color: p.textSecondary, fontSize: 13)),
              ),
              Text(
                Fmt.money(value),
                style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(child: ColoredBox(color: p.surfaceAlt)),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction,
                      child: ColoredBox(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        bar('Income', income, p.credit),
        const SizedBox(height: 16),
        bar('Expense', expense, p.debit),
      ],
    );
  }
}

/// Donut of expense categories with the total in the middle.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.centerLabel,
    required this.centerValue,
    this.size = 170,
  });

  final List<CategoryTotal> slices;
  final String centerLabel;
  final String centerValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      label: '$centerLabel $centerValue',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              size: Size.square(size),
              painter: _DonutPainter(slices: slices, track: p.surfaceAlt),
            ),
            SizedBox(
              width: size * 0.58,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(centerLabel, style: TextStyle(color: p.textMuted, fontSize: 12)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      centerValue,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.track});

  final List<CategoryTotal> slices;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final stroke = size.shortestSide * 0.16;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    final gap = slices.length > 1 ? 0.03 : 0.0;
    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = s.share * 2 * math.pi;
      if (sweep <= 0) continue;
      final drawn = math.max(sweep - gap, 0.01);
      canvas.drawArc(
        rect,
        start + gap / 2,
        drawn,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = Categories.colorFor(s.category),
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.track != track;
}

/// Weekly spending bars (Week 1 - Week 4). Handles all-zero data.
class SpendingTrendChart extends StatelessWidget {
  const SpendingTrendChart({
    super.key,
    required this.values,
    required this.labels,
    this.barAreaHeight = 140,
  });

  final List<double> values;
  final List<String> labels;
  final double barAreaHeight;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final p = context.pal;
    final scaler = MediaQuery.textScalerOf(context);
    final textHeight = scaler.scale(13) * 1.4;
    final maxValue = values.fold<double>(0, math.max);

    return SizedBox(
      height: barAreaHeight + textHeight * 2 + 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List<Widget>.generate(values.length, (i) {
          final v = values[i];
          final barHeight = maxValue <= 0 ? 4.0 : math.max(4.0, (v / maxValue) * barAreaHeight);
          final label = i < labels.length ? labels[i] : '';
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                SizedBox(
                  height: textHeight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      v > 0 ? Fmt.compact(v) : '',
                      style: TextStyle(color: p.textSecondary, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: barHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: v > 0 ? p.accent : p.surfaceAlt,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: textHeight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, style: TextStyle(color: p.textMuted, fontSize: 12)),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
