import 'package:flutter/material.dart';

import 'celebration_effect.dart';
import 'income_coin_burst_overlay.dart';
import 'particle_burst_overlay.dart';

/// Routes to expense confetti or income coin burst.
class TransactionCelebrationOverlay extends StatelessWidget {
  const TransactionCelebrationOverlay({
    super.key,
    required this.effect,
    required this.child,
    this.onComplete,
  });

  final CelebrationEffect effect;
  final Widget child;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final active = effect != CelebrationEffect.none;

    return switch (effect) {
      CelebrationEffect.incomeCoins => IncomeCoinBurstOverlay(
          active: active,
          onComplete: onComplete,
          child: child,
        ),
      CelebrationEffect.expenseConfetti => ParticleBurstOverlay(
          active: active,
          onComplete: onComplete,
          child: child,
        ),
      CelebrationEffect.none => ParticleBurstOverlay(
          active: false,
          onComplete: onComplete,
          child: child,
        ),
    };
  }
}
