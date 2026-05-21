import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Production-quality confetti celebration for expense logging.
class ParticleBurstOverlay extends StatefulWidget {
  const ParticleBurstOverlay({
    super.key,
    required this.active,
    required this.child,
    this.onComplete,
  });

  final bool active;
  final Widget child;
  final VoidCallback? onComplete;

  @override
  State<ParticleBurstOverlay> createState() => _ParticleBurstOverlayState();
}

class _ParticleBurstOverlayState extends State<ParticleBurstOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  final _rng = math.Random();
  List<_ConfettiPiece> _pieces = [];
  bool _playing = false;

  static const _duration = Duration(milliseconds: 3400);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _progress = CurvedAnimation(parent: _controller, curve: Curves.linear);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _playing = false);
        widget.onComplete?.call();
      }
    });
    if (widget.active) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _startBurst());
    }
  }

  @override
  void didUpdateWidget(covariant ParticleBurstOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active) _startBurst();
      });
    }
  }

  void _startBurst() {
    _controller
      ..stop()
      ..reset();
    _pieces = _ConfettiFactory(_rng).generate();
    setState(() => _playing = true);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_playing)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ProfessionalConfettiPainter(
                      pieces: _pieces,
                      t: _progress.value,
                    ),
                    isComplex: true,
                    willChange: true,
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

enum _PieceShape { rectangle, streamer, circle, diamond }

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.shape,
    required this.primary,
    required this.secondary,
    required this.width,
    required this.height,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.angularVelocity,
    required this.gravity,
    required this.drag,
    required this.flutterAmplitude,
    required this.flutterFrequency,
    required this.flutterPhase,
    required this.wind,
    required this.delay,
    required this.mass,
    required this.depth,
  });

  final _PieceShape shape;
  final Color primary;
  final Color secondary;
  final double width;
  final double height;
  final double vx;
  final double vy;
  final double rotation;
  final double angularVelocity;
  final double gravity;
  final double drag;
  final double flutterAmplitude;
  final double flutterFrequency;
  final double flutterPhase;
  final double wind;
  final double delay;
  final double mass;
  final double depth;
}

class _ConfettiFactory {
  _ConfettiFactory(this._rng);

  final math.Random _rng;

  static const _palette = <({Color a, Color b})>[
    (a: Color(0xFF0D9488), b: Color(0xFF5EEAD4)),
    (a: Color(0xFF0F766E), b: Color(0xFF99F6E4)),
    (a: Color(0xFF0369A1), b: Color(0xFF7DD3FC)),
    (a: Color(0xFFB45309), b: Color(0xFFFCD34D)),
    (a: Color(0xFFBE185D), b: Color(0xFFF9A8D4)),
    (a: Color(0xFF4F46E5), b: Color(0xFFC7D2FE)),
    (a: Color(0xFF475569), b: Color(0xFFCBD5E1)),
    (a: Color(0xFF059669), b: Color(0xFF6EE7B7)),
  ];

  static const _shapes = _PieceShape.values;

  List<_ConfettiPiece> generate() {
    final pieces = <_ConfettiPiece>[];

    void wave({
      required int count,
      required double speedMin,
      required double speedMax,
      required double delayMax,
      required double vyLift,
      required double depthMin,
      required double depthMax,
    }) {
      for (var i = 0; i < count; i++) {
        pieces.add(_create(
          speedMin: speedMin,
          speedMax: speedMax,
          delayMax: delayMax,
          vyLift: vyLift,
          depth: depthMin + _rng.nextDouble() * (depthMax - depthMin),
        ));
      }
    }

    wave(
      count: 42,
      speedMin: 300,
      speedMax: 480,
      delayMax: 0.05,
      vyLift: 110,
      depthMin: 0.55,
      depthMax: 1.0,
    );
    wave(
      count: 32,
      speedMin: 200,
      speedMax: 340,
      delayMax: 0.2,
      vyLift: 75,
      depthMin: 0.35,
      depthMax: 0.8,
    );
    wave(
      count: 20,
      speedMin: 120,
      speedMax: 220,
      delayMax: 0.38,
      vyLift: 50,
      depthMin: 0.15,
      depthMax: 0.55,
    );

    return pieces;
  }

  _ConfettiPiece _create({
    required double speedMin,
    required double speedMax,
    required double delayMax,
    required double vyLift,
    required double depth,
  }) {
    final colors = _palette[_rng.nextInt(_palette.length)];
    final angle = -math.pi * 0.88 + _rng.nextDouble() * math.pi * 1.76;
    final speed = speedMin + _rng.nextDouble() * (speedMax - speedMin);
    final shape = _shapes[_rng.nextInt(_shapes.length)];

    final (w, h) = switch (shape) {
      _PieceShape.rectangle => (6.0 + _rng.nextDouble() * 5, 3.0 + _rng.nextDouble() * 4),
      _PieceShape.streamer => (2.0 + _rng.nextDouble() * 2, 10.0 + _rng.nextDouble() * 14),
      _PieceShape.circle => (4.0 + _rng.nextDouble() * 3, 4.0 + _rng.nextDouble() * 3),
      _PieceShape.diamond => (5.0 + _rng.nextDouble() * 4, 5.0 + _rng.nextDouble() * 4),
    };

    return _ConfettiPiece(
      shape: shape,
      primary: colors.a,
      secondary: colors.b,
      width: w,
      height: h,
      vx: math.cos(angle) * speed,
      vy: math.sin(angle) * speed - vyLift,
      rotation: _rng.nextDouble() * math.pi * 2,
      angularVelocity: (_rng.nextDouble() - 0.5) * 9,
      gravity: 260 + _rng.nextDouble() * 90,
      drag: 0.9 + _rng.nextDouble() * 0.55,
      flutterAmplitude: 10 + _rng.nextDouble() * 22,
      flutterFrequency: 2.2 + _rng.nextDouble() * 2.8,
      flutterPhase: _rng.nextDouble() * math.pi * 2,
      wind: (_rng.nextDouble() - 0.5) * 42,
      delay: _rng.nextDouble() * delayMax,
      mass: 0.75 + _rng.nextDouble() * 0.65,
      depth: depth,
    );
  }
}

class _SimulatedPiece {
  _SimulatedPiece({
    required this.source,
    required this.x,
    required this.y,
    required this.rotation,
    required this.tilt,
    required this.opacity,
    required this.scale,
    required this.speed,
    required this.depthKey,
  });

  final _ConfettiPiece source;
  final double x;
  final double y;
  final double rotation;
  final double tilt;
  final double opacity;
  final double scale;
  final double speed;
  final double depthKey;
}

class _ProfessionalConfettiPainter extends CustomPainter {
  _ProfessionalConfettiPainter({required this.pieces, required this.t});

  final List<_ConfettiPiece> pieces;
  final double t;

  static const _simDuration = 3.2;

  static double _burstImpulse(double time) =>
      1 + 2.6 * math.exp(-time / 0.13);

  static double _lifecycleOpacity(double lt) {
    const fadeIn = 0.1;
    const holdUntil = 0.5;
    const fadeStart = 0.54;

    if (lt < fadeIn) return Curves.easeOut.transform(lt / fadeIn);
    if (lt < holdUntil) return 1;
    final fadeT = ((lt - fadeStart) / (1 - fadeStart)).clamp(0.0, 1.0);
    return 1 - Curves.easeIn.transform(fadeT);
  }

  static double _spawnScale(double lt) {
    const fadeIn = 0.12;
    if (lt >= fadeIn) return 1;
    return Curves.easeOutCubic.transform(lt / fadeIn);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.5, size.height * 0.7);

    _paintAmbientGlow(canvas, size, origin);

    final simulated = <_SimulatedPiece>[];

    for (final p in pieces) {
      final denom = (1 - p.delay).clamp(0.05, 1.0);
      final lt = ((t - p.delay) / denom).clamp(0.0, 1.0);
      if (lt <= 0) continue;

      final time = lt * _simDuration;
      final impulse = _burstImpulse(time);
      final drag = math.exp(-p.drag * time);
      final flutter = math.sin(p.flutterFrequency * time + p.flutterPhase);
      final gravityScale = time > 1.4 ? 0.5 : 1.0;

      final vx = p.vx * impulse * drag;
      final vy = p.vy * impulse * drag;
      final speed = math.sqrt(vx * vx + vy * vy);

      final x = origin.dx +
          vx * time +
          p.wind * time * 0.75 +
          flutter * p.flutterAmplitude * drag;
      final y = origin.dy +
          vy * time +
          0.5 * p.gravity * gravityScale * time * time / p.mass;

      final opacity = _lifecycleOpacity(lt) * (0.55 + p.depth * 0.45);
      final scale = _spawnScale(lt) * (0.72 + p.depth * 0.38);

      if (opacity < 0.025) continue;
      if (x < -60 || x > size.width + 60) continue;

      simulated.add(
        _SimulatedPiece(
          source: p,
          x: x,
          y: y,
          rotation: p.rotation + p.angularVelocity * time + flutter * 0.28,
          tilt: math.cos(time * p.flutterFrequency + p.flutterPhase) * 0.45,
          opacity: opacity,
          scale: scale,
          speed: speed,
          depthKey: y - p.depth * 200,
        ),
      );
    }

    simulated.sort((a, b) => a.depthKey.compareTo(b.depthKey));

    for (final s in simulated) {
      _paintPiece(canvas, s);
    }
  }

  void _paintAmbientGlow(Canvas canvas, Size size, Offset origin) {
    if (t > 0.2) return;
    final phase = Curves.easeOut.transform((t / 0.2).clamp(0.0, 1.0));
    final alpha = (1 - phase) * 0.22;

    final glowRect = Rect.fromCircle(center: origin, radius: 70);
    canvas.drawCircle(
      origin,
      24 + phase * 52,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF5EEAD4).withValues(alpha: alpha),
            const Color(0xFF0D9488).withValues(alpha: alpha * 0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(glowRect),
    );

    canvas.drawCircle(
      origin,
      8 + phase * 20,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * (1 - phase)
        ..color = Colors.white.withValues(alpha: alpha * 1.4),
    );
  }

  void _paintPiece(Canvas canvas, _SimulatedPiece s) {
    final p = s.source;
    final alpha = s.opacity;
    final w = p.width * s.scale;
    final h = p.height * s.scale;

    canvas.save();
    canvas.translate(s.x, s.y);
    canvas.rotate(s.rotation);
    canvas.transform(Matrix4.skewX(s.tilt).storage);

    if (s.speed > 180) {
      _paintMotionTrail(canvas, p, w, h, alpha, s.speed);
    }

    switch (p.shape) {
      case _PieceShape.rectangle:
        _paintRectanglePaper(canvas, p, w, h, alpha);
      case _PieceShape.streamer:
        _paintStreamer(canvas, p, w, h, alpha);
      case _PieceShape.circle:
        _paintCirclePaper(canvas, p, w, h, alpha);
      case _PieceShape.diamond:
        _paintDiamond(canvas, p, w, h, alpha);
    }

    canvas.restore();
  }

  void _paintMotionTrail(
    Canvas canvas,
    _ConfettiPiece p,
    double w,
    double h,
    double alpha,
    double speed,
  ) {
    final stretch = (speed / 400).clamp(0.0, 1.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-w * 0.35 * stretch, 0),
          width: w * (1 + stretch * 1.4),
          height: h * 0.85,
        ),
        Radius.circular(1),
      ),
      Paint()..color = p.primary.withValues(alpha: alpha * 0.12),
    );
  }

  void _paintRectanglePaper(
    Canvas canvas,
    _ConfettiPiece p,
    double w,
    double h,
    double alpha,
  ) {
    final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1.2));

    canvas.drawRRect(
      rrect.shift(const Offset(0.8, 1)),
      Paint()..color = Colors.black.withValues(alpha: alpha * 0.14),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.secondary.withValues(alpha: alpha),
            p.primary.withValues(alpha: alpha),
          ],
        ).createShader(rect),
    );

    canvas.drawLine(
      Offset(-w * 0.15, -h / 2),
      Offset(-w * 0.15, h / 2),
      Paint()
        ..strokeWidth = 0.6
        ..color = Colors.white.withValues(alpha: alpha * 0.35),
    );
  }

  void _paintStreamer(
    Canvas canvas,
    _ConfettiPiece p,
    double w,
    double h,
    double alpha,
  ) {
    final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(w / 2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            p.secondary.withValues(alpha: alpha * 0.9),
            p.primary.withValues(alpha: alpha),
            p.primary.withValues(alpha: alpha * 0.85),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
  }

  void _paintCirclePaper(
    Canvas canvas,
    _ConfettiPiece p,
    double w,
    double h,
    double alpha,
  ) {
    final r = (w + h) / 4;
    canvas.drawCircle(
      Offset(0.6, 0.8),
      r,
      Paint()..color = Colors.black.withValues(alpha: alpha * 0.12),
    );
    final circleRect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.25),
          radius: 1.0,
          colors: [
            p.secondary.withValues(alpha: alpha),
            p.primary.withValues(alpha: alpha),
          ],
        ).createShader(circleRect),
    );
  }

  void _paintDiamond(
    Canvas canvas,
    _ConfettiPiece p,
    double w,
    double h,
    double alpha,
  ) {
    final path = Path()
      ..moveTo(0, -h / 2)
      ..lineTo(w / 2, 0)
      ..lineTo(0, h / 2)
      ..lineTo(-w / 2, 0)
      ..close();

    canvas.drawPath(
      path.shift(const Offset(0.6, 0.9)),
      Paint()..color = Colors.black.withValues(alpha: alpha * 0.15),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            p.secondary.withValues(alpha: alpha),
            p.primary.withValues(alpha: alpha),
          ],
        ).createShader(Rect.fromLTWH(-w / 2, -h / 2, w, h)),
    );
  }

  @override
  bool shouldRepaint(covariant _ProfessionalConfettiPainter old) => old.t != t;
}
