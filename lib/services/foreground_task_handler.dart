import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../core/breath_phase.dart';
import '../core/breathing_session.dart';
import 'settings_store.dart';

/// Entry point re-run by Android in a dedicated background isolate. It must
/// stay top-level (not a class member) per flutter_foreground_task's contract.
@pragma('vm:entry-point')
void breathingTaskStartCallback() {
  FlutterForegroundTask.setTaskHandler(BreathingTaskHandler());
}

/// Drives the 4-7-8 cycle while the app is backgrounded or the screen is
/// off, playing a cue sound on every phase change and stopping itself once
/// the configured session length elapses.
class BreathingTaskHandler extends TaskHandler {
  final _settings = SettingsStore();
  final _player = AudioPlayer();

  BreathingSession _session = const BreathingSession();
  bool _soundEnabled = true;
  int _elapsedSeconds = 0;
  BreathPhase? _lastPhase;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final totalSeconds = await _settings.sessionTotalSeconds;
    _soundEnabled = await _settings.soundEnabled;
    _session = BreathingSession(
      totalDuration:
          totalSeconds == null ? null : Duration(seconds: totalSeconds),
    );
    _elapsedSeconds = 0;
    _lastPhase = null;
    await _player.setReleaseMode(ReleaseMode.stop);
    _emit(_session.stateAt(0));
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final state = _session.stateAt(_elapsedSeconds);

    if (state.phase != _lastPhase) {
      _lastPhase = state.phase;
      _playCue(state.phase.soundAsset);
    }

    _emit(state);

    if (state.finished) {
      _playCue('sounds/session_end.wav');
      FlutterForegroundTask.stopService();
      return;
    }

    _elapsedSeconds += 1;
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _player.dispose();
  }

  void _emit(SessionState state) {
    FlutterForegroundTask.sendDataToMain(<String, dynamic>{
      'phase': state.phase.name,
      'secondsRemainingInPhase': state.secondsRemainingInPhase,
      'elapsedSeconds': state.elapsedSeconds,
      'remainingSessionSeconds': state.remainingSessionSeconds,
      'finished': state.finished,
    });
  }

  Future<void> _playCue(String asset) async {
    if (!_soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Missing/undecodable audio asset should never crash the timer.
    }
  }
}
