import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Decorative wave lines used on the splash and sign-in screens.
/// Stops animating when the system asks for reduced motion.
class CyberWave extends StatefulWidget {
  const CyberWave({super.key, this.height = 120, this.animate = true});

  final double height;
  final bool animate;

  @override
  State<CyberWave> createState() => _CyberWaveState();
}

class _CyberWaveState extends State<CyberWave> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(CyberWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (widget.animate && !reduce) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _WavePainter(animation: _controller, color: context.pal.accent),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.animation, required this.color}) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final phase = animation.value * 2 * math.pi;
    for (var i = 0; i < 3; i++) {
      final path = Path();
      final amplitude = size.height * (0.2 - i * 0.04);
      final baseline = size.height * (0.4 + i * 0.16);
      final frequency = 1.2 + i * 0.4;
      final speed = 1 + i * 0.5;
      var first = true;
      for (double x = 0; x <= size.width; x += 4) {
        final y = baseline +
            amplitude * math.sin((x / size.width) * 2 * math.pi * frequency + phase * speed);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color.withValues(alpha: 0.38 - i * 0.1);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => oldDelegate.color != color;
}
