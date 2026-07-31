import 'package:breathe478/core/breath_phase.dart';
import 'package:breathe478/core/breathing_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreathingSession.stateAt (unlimited session)', () {
    const session = BreathingSession();

    test('cycle length is 19 seconds', () {
      expect(BreathingSession.cycleSeconds, 19);
    });

    test('starts in inhale at t=0', () {
      final s = session.stateAt(0);
      expect(s.phase, BreathPhase.inhale);
      expect(s.secondsIntoPhase, 0);
      expect(s.secondsRemainingInPhase, 4);
    });

    test('last second of inhale is t=3', () {
      final s = session.stateAt(3);
      expect(s.phase, BreathPhase.inhale);
      expect(s.secondsRemainingInPhase, 1);
    });

    test('hold begins exactly at t=4', () {
      final s = session.stateAt(4);
      expect(s.phase, BreathPhase.hold);
      expect(s.secondsIntoPhase, 0);
      expect(s.secondsRemainingInPhase, 7);
    });

    test('exhale begins exactly at t=11 (4+7)', () {
      final s = session.stateAt(11);
      expect(s.phase, BreathPhase.exhale);
      expect(s.secondsIntoPhase, 0);
      expect(s.secondsRemainingInPhase, 8);
    });

    test('last second of exhale is t=18', () {
      final s = session.stateAt(18);
      expect(s.phase, BreathPhase.exhale);
      expect(s.secondsRemainingInPhase, 1);
    });

    test('wraps back to inhale at t=19 (second cycle)', () {
      final s = session.stateAt(19);
      expect(s.phase, BreathPhase.inhale);
      expect(s.secondsIntoPhase, 0);
    });

    test('wraps correctly deep into later cycles', () {
      // 19 * 5 = 95, + 4 (inhale) + 7 (hold) = 106 -> exhale, 2s in.
      final s = session.stateAt(106);
      expect(s.phase, BreathPhase.exhale);
      expect(s.secondsIntoPhase, 2);
    });

    test('unlimited session never reports finished or a remaining time', () {
      final s = session.stateAt(10000);
      expect(s.finished, isFalse);
      expect(s.remainingSessionSeconds, isNull);
    });
  });

  group('BreathingSession.stateAt (timed session)', () {
    const session = BreathingSession(totalDuration: Duration(seconds: 60));

    test('reports remaining session seconds counting down', () {
      expect(session.stateAt(0).remainingSessionSeconds, 60);
      expect(session.stateAt(20).remainingSessionSeconds, 40);
    });

    test('not finished right before the total duration', () {
      expect(session.stateAt(59).finished, isFalse);
    });

    test('finished exactly at the total duration', () {
      expect(session.stateAt(60).finished, isTrue);
    });

    test('remaining session seconds never goes negative past the end', () {
      expect(session.stateAt(75).remainingSessionSeconds, 0);
    });
  });
}
