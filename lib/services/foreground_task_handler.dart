import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry point re-run by Android in a dedicated background isolate. It must
/// stay top-level (not a class member) per flutter_foreground_task's contract.
@pragma('vm:entry-point')
void breathingTaskStartCallback() {
  FlutterForegroundTask.setTaskHandler(KeepAliveTaskHandler());
}

/// Deliberately does nothing.
///
/// The session clock, the phase transitions and the cue sounds all live in
/// the UI isolate ([BreathingController]) instead. This handler exists only
/// so that a foreground service is running, which is what actually keeps the
/// process alive (and holds a wakelock) once the screen turns off.
///
/// Keeping it empty is a deliberate robustness choice: plugins such as
/// shared_preferences and audioplayers are not reliably registered inside a
/// background isolate, and when they threw here the UI — which used to
/// depend on this isolate reporting state back — was left permanently blank
/// with no error shown.
class KeepAliveTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
