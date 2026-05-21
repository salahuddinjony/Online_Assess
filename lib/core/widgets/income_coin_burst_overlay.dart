import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Realistic rising gold coins for income transactions.
class IncomeCoinBurstOverlay extends StatefulWidget {
  const IncomeCoinBurstOverlay({
    super.key,
    required this.active,
    required this.child,
    this.onComplete,
  });

  final bool active;
  final Widget child;
  final VoidCallback? onComplete;

  @override
  State<IncomeCoinBurstOverlay> createState() => _IncomeCoinBurstOverlayState();
}

class _IncomeCoinBurstOverlayState extends State<IncomeCoinBurstOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  final _rng = math.Random();
  List<_Coin> _coins = [];
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
      SchedulerBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void didUpdateWidget(covariant IncomeCoinBurstOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active) _start();
      });
    }
  }

  void _start() {
    _controller
      ..stop()
      ..reset();
    _coins = _CoinFactory(_rng).generate();
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
                    painter: _RealisticCoinPainter(
                      coins: _coins,
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

class _CoinPalette {
  const _CoinPalette({
    required this.rimDark,
    required this.rimLight,
    required this.faceCenter,
    required this.faceEdge,
    required this.symbol,
  });

  final Color rimDark;
  final Color rimLight;
  final Color faceCenter;
  final Color faceEdge;
  final Color symbol;
}

class _Coin {
  const _Coin({
    required this.radius,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.spin,
    required this.tiltSpeed,
    required this.tiltPhase,
    required this.delay,
    required this.wobblePhase,
    required this.depth,
    required this.palette,
    required this.wobbleAmp,
  });

  final double radius;
  final double vx;
  final double vy;
  final double rotation;
  final double spin;
  final double tiltSpeed;
  final double tiltPhase;
  final double delay;
  final double wobblePhase;
  final double depth;
  final _CoinPalette palette;
  final double wobbleAmp;
}

class _CoinFactory {
  _CoinFactory(this._rng);

  final math.Random _rng;

  static const _palettes = [
    _CoinPalette(
      rimDark: Color(0xFF92400E),
      rimLight: Color(0xFFFDE68A),
      faceCenter: Color(0xFFFEF3C7),
      faceEdge: Color(0xFFD97706),
      symbol: Color(0xFF78350F),
    ),
    _CoinPalette(
      rimDark: Color(0xFF047857),
      rimLight: Color(0xFF6EE7B7),
      faceCenter: Color(0xFFECFDF5),
      faceEdge: Color(0xFF059669),
      symbol: Color(0xFF064E3B),
    ),
    _CoinPalette(
      rimDark: Color(0xFF854D0E),
      rimLight: Color(0xFFFBBF24),
      faceCenter: Color(0xFFFFFBEB),
      faceEdge: Color(0xFFCA8A04),
      symbol: Color(0xFF713F12),
    ),
  ];

  List<_Coin> generate() {
    final coins = <_Coin>[];

    void addWave(int count, double vyMin, double vyMax, double delayMax, double depthMin, double depthMax) {
      for (var i = 0; i < count; i++) {
        final angle = (_rng.nextDouble() - 0.5) * 1.1;
        final speed = 240 + _rng.nextDouble() * 200;
        coins.add(
          _Coin(
            radius: 6 + _rng.nextDouble() * 5,
            vx: math.sin(angle) * speed * 0.55,
            vy: -(vyMin + _rng.nextDouble() * (vyMax - vyMin)),
            rotation: _rng.nextDouble() * math.pi * 2,
            spin: (_rng.nextDouble() - 0.5) * 5,
            tiltSpeed: 4 + _rng.nextDouble() * 3,
            tiltPhase: _rng.nextDouble() * math.pi * 2,
            delay: _rng.nextDouble() * delayMax,
            wobblePhase: _rng.nextDouble() * math.pi * 2,
            depth: depthMin + _rng.nextDouble() * (depthMax - depthMin),
            palette: _palettes[_rng.nextInt(_palettes.length)],
            wobbleAmp: 8 + _rng.nextDouble() * 16,
          ),
        );
      }
    }

    addWave(22, 280, 420, 0.06, 0.6, 1.0);
    addWave(16, 200, 320, 0.2, 0.35, 0.75);
    addWave(10, 140, 220, 0.35, 0.15, 0.5);

    return coins;
  }
}

class _SimulatedCoin {
  _SimulatedCoin({
    required this.coin,
    required this.x,
    required this.y,
    required this.rotation,
    required this.scaleY,
    required this.opacity,
    required this.scale,
    required this.depth,
    required this.speed,
  });

  final _Coin coin;
  final double x;
  final double y;
  final double rotation;
  final double scaleY;
  final double opacity;
  final double scale;
  final double depth;
  final double speed;
}

class _RealisticCoinPainter extends CustomPainter {
  _RealisticCoinPainter({required this.coins, required this.t});

  final List<_Coin> coins;
  final double t;

  static const _simDuration = 3.0;

  static double _burstImpulse(double time) => 1 + 2.4 * math.exp(-time / 0.14);

  static double _lifecycleOpacity(double lt) {
    const fadeIn = 0.1;
    const hold = 0.52;
    if (lt < fadeIn) return Curves.easeOut.transform(lt / fadeIn);
    if (lt < hold) return 1;
    final fade = ((lt - hold) / (1 - hold)).clamp(0.0, 1.0);
    return 1 - Curves.easeInCubic.transform(fade);
  }

  static double _spawnScale(double lt) {
    if (lt >= 0.12) return 1;
    return Curves.easeOutCubic.transform(lt / 0.12);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.5, size.height * 0.74);
    final simulated = <_SimulatedCoin>[];

    _paintLaunchGlow(canvas, origin);

    for (final c in coins) {
      final denom = (1 - c.delay).clamp(0.05, 1.0);
      final lt = ((t - c.delay) / denom).clamp(0.0, 1.0);
      if (lt <= 0) continue;

      final time = lt * _simDuration;
      final impulse = _burstImpulse(time);
      final drag = math.exp(-0.55 * time);
      final gravity = time > 1.3 ? 70.0 : 45.0;

      final vx = c.vx * impulse * drag;
      final vy = c.vy * impulse * drag;
      final speed = math.sqrt(vx * vx + vy * vy);

      final x = origin.dx +
          vx * time +
          math.sin(time * 2.2 + c.wobblePhase) * c.wobbleAmp * drag;
      final y = origin.dy + vy * time + 0.5 * gravity * time * time;

      final tilt = math.sin(time * c.tiltSpeed + c.tiltPhase);
      final scaleY = 0.28 + 0.72 * (0.55 + 0.45 * tilt.abs());
      final opacity = _lifecycleOpacity(lt) * (0.5 + c.depth * 0.5);
      final scale = _spawnScale(lt) * (0.75 + c.depth * 0.35);

      if (opacity < 0.025 || y < -100) continue;
      if (x < -60 || x > size.width + 60) continue;

      simulated.add(
        _SimulatedCoin(
          coin: c,
          x: x,
          y: y,
          rotation: c.rotation + c.spin * time,
          scaleY: scaleY,
          opacity: opacity,
          scale: scale,
          depth: y - c.depth * 100,
          speed: speed,
        ),
      );
    }

    simulated.sort((a, b) => a.depth.compareTo(b.depth));

    for (final s in simulated) {
      _paintCoin(canvas, s);
    }
  }

  void _paintLaunchGlow(Canvas canvas, Offset origin) {
    if (t > 0.18) return;
    final p = Curves.easeOut.transform((t / 0.18).clamp(0.0, 1.0));
    final alpha = (1 - p) * 0.28;
    final rect = Rect.fromCircle(center: origin, radius: 55);
    canvas.drawCircle(
      origin,
      8 + p * 28,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFEF08A).withValues(alpha: alpha),
            const Color(0xFF34D399).withValues(alpha: alpha * 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(rect),
    );
  }

  void _paintCoin(Canvas canvas, _SimulatedCoin s) {
    final c = s.coin;
    final p = c.palette;
    final r = c.radius * s.scale;
    final alpha = s.opacity;

    canvas.save();
    canvas.translate(s.x, s.y);
    canvas.rotate(s.rotation);
    canvas.scale(1, s.scaleY);

    if (s.speed > 200) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, r * 0.6),
          width: r * 1.4,
          height: r * 0.5,
        ),
        Paint()..color = p.rimLight.withValues(alpha: alpha * 0.08),
      );
    }

    if (s.scaleY < 0.42) {
      _paintCoinEdge(canvas, r, p, alpha);
    } else {
      _paintCoinFace(canvas, r, p, alpha, s.scaleY);
    }

    canvas.restore();
  }

  void _paintCoinEdge(Canvas canvas, double r, _CoinPalette p, double alpha) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.35, height: r * 1.05),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            p.rimDark.withValues(alpha: alpha),
            p.rimLight.withValues(alpha: alpha),
            p.rimDark.withValues(alpha: alpha * 0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCenter(
          center: Offset.zero,
          width: r * 0.4,
          height: r * 1.1,
        )),
    );
  }

  void _paintCoinFace(
    Canvas canvas,
    double r,
    _CoinPalette p,
    double alpha,
    double scaleY,
  ) {
    final shadowOffset = Offset(1.2, 2 * scaleY);

    canvas.drawCircle(
      Offset.zero + shadowOffset,
      r,
      Paint()..color = Colors.black.withValues(alpha: alpha * 0.22),
    );

    final faceRect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.32),
          radius: 1.05,
          colors: [
            p.faceCenter.withValues(alpha: alpha),
            p.faceEdge.withValues(alpha: alpha),
            p.rimDark.withValues(alpha: alpha * 0.95),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(faceRect),
    );

    canvas.drawCircle(
      Offset.zero,
      r * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.11
        ..shader = SweepGradient(
          colors: [
            p.rimDark.withValues(alpha: alpha),
            p.rimLight.withValues(alpha: alpha),
            p.rimDark.withValues(alpha: alpha * 0.85),
            p.rimLight.withValues(alpha: alpha * 0.7),
            p.rimDark.withValues(alpha: alpha),
          ],
        ).createShader(faceRect),
    );

    canvas.drawArc(
      Rect.fromCircle(center: const Offset(-0.15, -0.2), radius: r * 0.75),
      -2.6,
      1.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: alpha * 0.45),
    );

    final symbolSize = r * 0.95;
    final tp = TextPainter(
      text: TextSpan(
        text: '\$',
        style: TextStyle(
          fontSize: symbolSize,
          fontWeight: FontWeight.w800,
          foreground: Paint()
            ..style = PaintingStyle.fill
            ..color = p.symbol.withValues(alpha: alpha * 0.85),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(0.5, 1.2);
    tp.paint(
      canvas,
      Offset(-tp.width / 2, -tp.height / 2 - r * 0.02),
    );
    canvas.restore();

    tp.paint(
      canvas,
      Offset(-tp.width / 2, -tp.height / 2 - r * 0.02),
    );
  }

  @override
  bool shouldRepaint(covariant _RealisticCoinPainter old) => old.t != t;
}
