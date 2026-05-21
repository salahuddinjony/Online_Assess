import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated budget arc gauge with smooth ratio transitions.
class BudgetArcMeter extends StatefulWidget {
  const BudgetArcMeter({
    super.key,
    required this.ratio,
    required this.spent,
    required this.limit,
    this.size = 160,
  });

  final double ratio;
  final double spent;
  final double limit;
  final double size;

  @override
  State<BudgetArcMeter> createState() => _BudgetArcMeterState();
}

class _BudgetArcMeterState extends State<BudgetArcMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curve;
  double _fromRatio = 0;
  double _toRatio = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _toRatio = widget.ratio.clamp(0.0, 1.0);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant BudgetArcMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.ratio.clamp(0.0, 1.0);
    if ((next - _toRatio).abs() > 0.001) {
      _fromRatio = _lerp(_fromRatio, _toRatio, _curve.value);
      _toRatio = next;
      _controller.forward(from: 0);
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) {
          final ratio =
              _lerp(_fromRatio, _toRatio, _curve.value).clamp(0.0, 1.0);
          final percent = (ratio * 100).round();
          return CustomPaint(
            painter: _BudgetArcPainter(
              ratio: ratio,
              accent: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${widget.spent.toStringAsFixed(0)} / \$${widget.limit.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BudgetArcPainter extends CustomPainter {
  _BudgetArcPainter({required this.ratio, required this.accent});

  final double ratio;
  final Color accent;

  static const _startAngle = math.pi * 0.75;
  static const _sweepTotal = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);

    _drawTicks(canvas, center, radius);

    final track = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, _sweepTotal, false, track);

    if (ratio <= 0) return;

    final sweep = _sweepTotal * ratio;
    final progress = Paint()
      ..shader = SweepGradient(
        colors: [
          accent.withValues(alpha: 0.55),
          accent,
          Color.lerp(accent, Colors.amber.shade600, ratio * 0.35)!,
        ],
        stops: const [0.0, 0.55, 1.0],
        startAngle: _startAngle,
        endAngle: _startAngle + _sweepTotal,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, sweep, false, progress);

    final tipAngle = _startAngle + sweep;
    final tip = center +
        Offset(math.cos(tipAngle), math.sin(tipAngle)) * radius;
    canvas.drawCircle(
      tip,
      7,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(tip, 5, Paint()..color = accent);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    const tickCount = 12;
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.25)
      ..strokeWidth = 1.2;
    for (var i = 0; i <= tickCount; i++) {
      final t = i / tickCount;
      final angle = _startAngle + _sweepTotal * t;
      final inner = radius - 6;
      final outer = radius - 2;
      final p1 = center +
          Offset(math.cos(angle), math.sin(angle)) * inner;
      final p2 = center +
          Offset(math.cos(angle), math.sin(angle)) * outer;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetArcPainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.accent != accent;
  }
}
