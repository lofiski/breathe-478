import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../core/breath_phase.dart';
import '../core/breathing_session.dart';
import 'cue_player.dart';
import 'foreground_task_handler.dart';

/// Outcome of a start request. The session always starts locally; these
/// values only describe whether background survival could be secured too.
enum StartOutcome {
  /// Session running and a foreground service is keeping it alive.
  running,

  /// Session running, but the OS refused the foreground service, so it may
  /// stop once the screen turns off.
  runningWithoutBackground,
}

/// Owns the session clock in the UI isolate.
///
/// The timer is anchored to wall-clock time rather than counting ticks, so
/// the session stays accurate even if timer callbacks are delayed or the app
/// is backgrounded and later resumed.
class BreathingController extends ChangeNotifier {
  final _cues = CuePlayer();

  Timer? _timer;
  DateTime? _startedAt;
  BreathingSession _session = const BreathingSession();
  bool _soundEnabled = true;
  BreathPhase? _lastPhase;

  /// Null when no session is running.
  SessionState? state;

  /// Set when the foreground service could not be started; surfaced once to
  /// explain why a locked screen may interrupt the session.
  String? backgroundWarning;

  bool get isRunning => _timer != null;

  static void initPlatform() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'breathe478_session',
        channelName: '呼吸训练进行中',
        channelDescription: '会话进行期间保持计时与提示音在后台运行。',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // The handler is intentionally idle; the UI isolate drives the
        // session. A slow heartbeat is enough to keep the service healthy.
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  Future<StartOutcome> start({
    required Duration? totalDuration,
    required bool soundEnabled,
  }) async {
    await stop();

    _soundEnabled = soundEnabled;
    _session = BreathingSession(totalDuration: totalDuration);
    _startedAt = DateTime.now();
    _lastPhase = null;
    backgroundWarning = null;

    if (_soundEnabled) {
      await _cues.preload();
    }

    // Start ticking first so the UI responds immediately and unconditionally,
    // even if every platform call below fails.
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    _tick();
    notifyListeners();

    final outcome = await _startForegroundService();
    notifyListeners();
    return outcome;
  }

  Future<StartOutcome> _startForegroundService() async {
    try {
      var permission = await FlutterForegroundTask.checkNotificationPermission();
      if (permission != NotificationPermission.granted) {
        permission = await FlutterForegroundTask.requestNotificationPermission();
      }
      if (permission != NotificationPermission.granted) {
        backgroundWarning = '未授予通知权限，熄屏后可能会中断。可在系统设置中允许通知后重试。';
        return StartOutcome.runningWithoutBackground;
      }

      // startService reports failure by RETURNING a ServiceRequestFailure,
      // not by throwing — ignoring the result is what previously made a
      // failed start look like the button doing nothing at all.
      final alreadyRunning = await FlutterForegroundTask.isRunningService;
      final ServiceRequestResult result;
      if (alreadyRunning) {
        result = await FlutterForegroundTask.restartService();
      } else {
        result = await FlutterForegroundTask.startService(
          serviceId: 478,
          notificationTitle: '478 呼吸训练进行中',
          notificationText: '吸气 4 秒 · 屏息 7 秒 · 呼气 8 秒',
          callback: breathingTaskStartCallback,
        );
      }

      if (result is ServiceRequestFailure) {
        backgroundWarning = '后台保活启动失败（${result.error}），熄屏后可能会中断。';
        return StartOutcome.runningWithoutBackground;
      }
      return StartOutcome.running;
    } catch (error) {
      backgroundWarning = '后台保活启动失败（$error），熄屏后可能会中断。';
      return StartOutcome.runningWithoutBackground;
    }
  }

  void _tick() {
    final startedAt = _startedAt;
    if (startedAt == null) return;

    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    final next = _session.stateAt(elapsed);

    if (next.finished) {
      _playCue(CuePlayer.sessionEndAsset);
      // Give the closing chime time to play before tearing down the service.
      Future.delayed(const Duration(milliseconds: 1200), stop);
      _timer?.cancel();
      _timer = null;
      state = null;
      _startedAt = null;
      notifyListeners();
      return;
    }

    if (next.phase != _lastPhase) {
      _lastPhase = next.phase;
      _playCue(next.phase.soundAsset);
      _updateNotification(next);
    }

    // Tick at 200ms so a phase boundary is caught promptly, but only rebuild
    // the UI when the displayed second actually changes.
    final changed = state == null ||
        state!.elapsedSeconds != next.elapsedSeconds ||
        state!.phase != next.phase;
    state = next;
    if (changed) notifyListeners();
  }

  void _playCue(String asset) {
    if (!_soundEnabled) return;
    unawaited(_cues.play(asset));
  }

  void _updateNotification(SessionState state) {
    final remaining = state.remainingSessionSeconds;
    final suffix = remaining == null
        ? ''
        : ' · 剩余 ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}';
    unawaited(_tryUpdateNotification('${state.phase.label}$suffix'));
  }

  Future<void> _tryUpdateNotification(String text) async {
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: '478 呼吸训练进行中',
        notificationText: text,
      );
    } catch (_) {
      // The notification is a nicety; never let it disturb the session.
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _startedAt = null;
    _lastPhase = null;
    state = null;
    notifyListeners();

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {
      // Nothing useful to do if the service was already gone.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    unawaited(_cues.dispose());
    super.dispose();
  }
}
