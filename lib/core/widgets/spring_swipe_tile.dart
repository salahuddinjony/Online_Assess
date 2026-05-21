import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Swipe-to-delete with spring snap-back and a fast slide-out dismiss.
class SpringSwipeTile extends StatefulWidget {
  const SpringSwipeTile({
    super.key,
    required this.child,
    required this.onDismissed,
  });

  final Widget child;
  final VoidCallback onDismissed;

  @override
  State<SpringSwipeTile> createState() => _SpringSwipeTileState();
}

class _SpringSwipeTileState extends State<SpringSwipeTile>
    with TickerProviderStateMixin {
  late AnimationController _spring;
  late AnimationController _dismissCtrl;
  Animation<double>? _dismissOffset;
  double _offset = 0;
  bool _dismissing = false;

  static const _threshold = 96.0;
  static const _maxDrag = 220.0;
  static const _snap = SpringDescription(mass: 0.7, stiffness: 280, damping: 22);

  @override
  void initState() {
    super.initState();
    _spring = AnimationController.unbounded(vsync: this)
      ..addListener(_onSpringTick);
    _dismissCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(_onDismissTick);
  }

  void _onSpringTick() {
    if (!_dismissing && mounted) setState(() => _offset = _spring.value);
  }

  void _onDismissTick() {
    if (_dismissing && _dismissOffset != null && mounted) {
      setState(() => _offset = _dismissOffset!.value);
    }
  }

  @override
  void dispose() {
    _spring.dispose();
    _dismissCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dismissing) return;
    _spring.stop();
    _offset = (_offset + details.delta.dx).clamp(-_maxDrag, 0);
    _spring.value = _offset;
    setState(() {});
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_dismissing) return;

    final vx = details.velocity.pixelsPerSecond.dx;
    final shouldDismiss = _offset.abs() >= _threshold || vx < -900;

    if (shouldDismiss) {
      await _runDismiss();
      return;
    }

    _spring.stop();
    _spring.value = _offset;
    await _spring.animateWith(SpringSimulation(_snap, _offset, 0, vx));
    if (mounted) setState(() => _offset = 0);
  }

  Future<void> _runDismiss() async {
    _dismissing = true;
    _spring.stop();

    final width = MediaQuery.sizeOf(context).width;
    final begin = _offset;
    final end = -width * 1.05;

    _dismissOffset = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _dismissCtrl, curve: Curves.easeInCubic),
    );

    await _dismissCtrl.forward(from: 0);
    _dismissCtrl.reset();

    if (mounted) widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (_dismissing && _offset.abs() >= width) {
      return const SizedBox.shrink();
    }

    final rawProgress = (_offset.abs() / _threshold).clamp(0.0, 1.0);
    final progress = Curves.easeOutCubic.transform(rawProgress);
    final showBackground = !_dismissing && rawProgress > 0.02;
    final childOpacity =
        _dismissing ? (1 - _dismissCtrl.value).clamp(0.0, 1.0) : 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (showBackground)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.red.shade50.withValues(alpha: progress * 0.9),
                      Colors.red.shade100.withValues(alpha: progress),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 20 + progress * 6),
                    child: Icon(
                      Icons.delete_rounded,
                      color: Color.lerp(
                        Colors.red.shade300,
                        Colors.red.shade700,
                        progress,
                      ),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: Opacity(
                opacity: childOpacity,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
