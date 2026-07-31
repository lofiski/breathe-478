import 'package:flutter/material.dart';

import '../../core/breath_phase.dart';
import '../theme/app_theme.dart';

/// The circle grows through inhale, holds, then shrinks through exhale.
/// Because [AnimatedContainer] only restarts its tween when the *target*
/// value changes, feeding it a fresh per-phase duration every tick from the
/// service is safe: it only takes effect at the instant the phase flips.
class BreathingCircle extends StatelessWidget {
  const BreathingCircle({
    super.key,
    required this.phase,
    required this.secondsRemaining,
  });

  final BreathPhase? phase;
  final int? secondsRemaining;

  double get _targetSize => switch (phase) {
        BreathPhase.inhale => 280,
        BreathPhase.hold => 280,
        BreathPhase.exhale => 160,
        null => 200,
      };

  Duration get _duration => phase == null
      ? const Duration(milliseconds: 400)
      : Duration(seconds: phase!.seconds);

  @override
  Widget build(BuildContext context) {
    final color = PhaseColors.of(phase);
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: _duration,
      curve: Curves.easeInOut,
      width: _targetSize,
      height: _targetSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 48,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(phase?.label ?? '准备好了吗', style: textTheme.headlineMedium),
          if (secondsRemaining != null) ...[
            const SizedBox(height: 8),
            Text('$secondsRemaining', style: textTheme.displayLarge),
          ],
        ],
      ),
    );
  }
}
