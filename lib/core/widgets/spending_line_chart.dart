import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SpendingLineChart extends StatefulWidget {
  const SpendingLineChart({
    super.key,
    required this.values,
    this.height = 140,
    this.labels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  });

  final List<double> values;
  final double height;
  final List<String> labels;

  @override
  State<SpendingLineChart> createState() => _SpendingLineChartState();
}

class _SpendingLineChartState extends State<SpendingLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _reveal;
  List<double> _fromValues = [];
  List<double> _toValues = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _reveal = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _toValues = List<double>.from(widget.values);
    _fromValues = List<double>.filled(_toValues.length, 0);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SpendingLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.values, widget.values)) {
      _fromValues = _interpolateValues(_fromValues, _toValues, _reveal.value);
      _toValues = List<double>.from(widget.values);
      _controller.forward(from: 0);
    }
  }

  List<double> _interpolateValues(
    List<double> from,
    List<double> to,
    double t,
  ) {
    final len = math.max(from.length, to.length);
    return List<double>.generate(len, (i) {
      final a = i < from.length ? from[i] : 0.0;
      final b = i < to.length ? to[i] : 0.0;
      return a + (b - a) * t;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _reveal,
            builder: (context, _) {
              final animatedValues =
                  _interpolateValues(_fromValues, _toValues, _reveal.value);
              return CustomPaint(
                painter: _SpendingLineChartPainter(
                  values: animatedValues,
                  reveal: _reveal.value,
                  lineColor: primary,
                  fillColor: primary.withValues(alpha: 0.12),
                  gridColor: primary.withValues(alpha: 0.08),
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: widget.labels
              .map(
                (l) => Text(
                  l,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SpendingLineChartPainter extends CustomPainter {
  _SpendingLineChartPainter({
    required this.values,
    required this.reveal,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<double> values;
  final double reveal;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce(math.max);
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.15;
    final chartBottom = size.height - 8;
    final chartTop = 12.0;
    final chartHeight = chartBottom - chartTop;

    for (var i = 0; i <= 3; i++) {
      final y = chartTop + chartHeight * (i / 3);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
    }

    final stepX = size.width / (values.length - 1).clamp(1, values.length);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] / maxY).clamp(0.0, 1.0);
      final y = chartBottom - normalized * chartHeight;
      points.add(Offset(x, y));
    }

    final smoothPath = _buildSmoothPath(points);
    final metrics = smoothPath.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final visible = metric.length * reveal;
    final drawn = metric.extractPath(0, visible);

    final fillPath = Path.from(drawn)
      ..lineTo(drawn.getBounds().right, chartBottom)
      ..lineTo(0, chartBottom)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillColor, fillColor.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      drawn,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < points.length; i++) {
      final threshold = (i + 1) / points.length;
      if (reveal < threshold - 0.08) continue;
      final dotReveal = ((reveal - (threshold - 0.15)) / 0.2).clamp(0.0, 1.0);
      final p = points[i];
      canvas.drawCircle(
        p,
        4.5 * dotReveal,
        Paint()..color = lineColor.withValues(alpha: dotReveal),
      );
      canvas.drawCircle(
        p,
        2,
        Paint()..color = Colors.white.withValues(alpha: dotReveal * 0.9),
      );
    }
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length < 2) return path;

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _SpendingLineChartPainter old) {
    return old.reveal != reveal ||
        !listEquals(old.values, values) ||
        old.lineColor != lineColor;
  }
}
