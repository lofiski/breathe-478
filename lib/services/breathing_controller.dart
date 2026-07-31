import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../core/breath_phase.dart';
import '../core/breathing_session.dart';
import 'foreground_task_handler.dart';
import 'settings_store.dart';

enum StartResult { ok, notificationPermissionDenied }

/// UI-facing handle to the background breathing session. The background
/// isolate ([BreathingTaskHandler]) owns the real clock; this class only
/// mirrors the latest state it reports and forwards start/stop requests.
class BreathingController extends ChangeNotifier {
  BreathingController() {
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  final _settings = SettingsStore();

  /// Null when no session is running.
  SessionState? state;

  bool get isRunning => state != null;

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
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  void _onTaskData(Object data) {
    if (data is! Map) return;
    if (data['finished'] == true) {
      state = null;
    } else {
      state = SessionState(
        phase: BreathPhase.values.byName(data['phase'] as String),
        secondsIntoPhase: 0,
        secondsRemainingInPhase: data['secondsRemainingInPhase'] as int,
        elapsedSeconds: data['elapsedSeconds'] as int,
        remainingSessionSeconds: data['remainingSessionSeconds'] as int?,
        finished: false,
      );
    }
    notifyListeners();
  }

  Future<StartResult> start({
    required Duration? totalDuration,
    required bool soundEnabled,
  }) async {
    var permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      permission = await FlutterForegroundTask.requestNotificationPermission();
    }
    if (permission != NotificationPermission.granted) {
      return StartResult.notificationPermissionDenied;
    }

    await _settings.setSessionTotalSeconds(totalDuration?.inSeconds);
    await _settings.setSoundEnabled(soundEnabled);

    await FlutterForegroundTask.startService(
      serviceId: 478,
      notificationTitle: '478 呼吸训练进行中',
      notificationText: '吸气 4 秒 · 屏息 7 秒 · 呼气 8 秒，点击返回',
      callback: breathingTaskStartCallback,
    );
    return StartResult.ok;
  }

  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
    state = null;
    notifyListeners();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    super.dispose();
  }
}
