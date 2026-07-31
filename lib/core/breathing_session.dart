import 'breath_phase.dart';

/// Snapshot of the breathing session at a given elapsed second.
class SessionState {
  const SessionState({
    required this.phase,
    required this.secondsIntoPhase,
    required this.secondsRemainingInPhase,
    required this.elapsedSeconds,
    required this.remainingSessionSeconds,
    required this.finished,
  });

  final BreathPhase phase;
  final int secondsIntoPhase;
  final int secondsRemainingInPhase;
  final int elapsedSeconds;

  /// Null when the session has no fixed end (runs until stopped manually).
  final int? remainingSessionSeconds;
  final bool finished;
}

/// Pure calculator that maps elapsed seconds to a [SessionState].
///
/// Kept free of Flutter/platform dependencies so it can run identically in
/// the UI isolate and in the background foreground-service isolate, and be
/// unit tested without a device.
class BreathingSession {
  const BreathingSession({this.totalDuration});

  /// Total session length, or null for an unlimited session (manual stop).
  final Duration? totalDuration;

  static int get cycleSeconds =>
      BreathPhase.values.fold(0, (sum, p) => sum + p.seconds);

  SessionState stateAt(int elapsedSeconds) {
    final total = totalDuration?.inSeconds;
    final finished = total != null && elapsedSeconds >= total;

    final t = elapsedSeconds % cycleSeconds;
    var acc = 0;
    for (final phase in BreathPhase.values) {
      final end = acc + phase.seconds;
      if (t < end) {
        final secondsIntoPhase = t - acc;
        return SessionState(
          phase: phase,
          secondsIntoPhase: secondsIntoPhase,
          secondsRemainingInPhase: phase.seconds - secondsIntoPhase,
          elapsedSeconds: elapsedSeconds,
          remainingSessionSeconds:
              total == null ? null : (total - elapsedSeconds).clamp(0, total),
          finished: finished,
        );
      }
      acc = end;
    }

    // t is always < cycleSeconds, so the loop above always returns.
    throw StateError('unreachable: t=$t cycleSeconds=$cycleSeconds');
  }
}
