import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's last-used session settings and, while a session is
/// running, the config needed by the background isolate to start itself
/// (SharedPreferences is readable from any isolate, unlike in-memory state).
class SettingsStore {
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyKeepScreenOn = 'keep_screen_on';
  static const _keyLastMinutes = 'last_minutes'; // -1 means unlimited
  static const _keySessionTotalSeconds = 'session_total_seconds'; // -1 = unlimited

  Future<bool> get soundEnabled async =>
      (await SharedPreferences.getInstance()).getBool(_keySoundEnabled) ?? true;

  Future<void> setSoundEnabled(bool value) async {
    (await SharedPreferences.getInstance()).setBool(_keySoundEnabled, value);
  }

  Future<bool> get keepScreenOn async =>
      (await SharedPreferences.getInstance()).getBool(_keyKeepScreenOn) ?? false;

  Future<void> setKeepScreenOn(bool value) async {
    (await SharedPreferences.getInstance()).setBool(_keyKeepScreenOn, value);
  }

  /// Null means unlimited (no auto-stop).
  Future<int?> get lastMinutes async {
    final value =
        (await SharedPreferences.getInstance()).getInt(_keyLastMinutes) ?? 7;
    return value == -1 ? null : value;
  }

  Future<void> setLastMinutes(int? minutes) async {
    (await SharedPreferences.getInstance())
        .setInt(_keyLastMinutes, minutes ?? -1);
  }

  /// Read by the background isolate's TaskHandler on start.
  Future<void> setSessionTotalSeconds(int? seconds) async {
    (await SharedPreferences.getInstance())
        .setInt(_keySessionTotalSeconds, seconds ?? -1);
  }

  Future<int?> get sessionTotalSeconds async {
    final value = (await SharedPreferences.getInstance())
            .getInt(_keySessionTotalSeconds) ??
        -1;
    return value == -1 ? null : value;
  }
}
