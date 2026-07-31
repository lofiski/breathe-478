import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../services/breathing_controller.dart';
import '../services/settings_store.dart';
import 'widgets/breathing_circle.dart';
import 'widgets/duration_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = BreathingController();
  final _settings = SettingsStore();

  int? _selectedMinutes = 7;
  bool _soundEnabled = true;
  bool _keepScreenOn = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final minutes = await _settings.lastMinutes;
    final sound = await _settings.soundEnabled;
    final screenOn = await _settings.keepScreenOn;
    if (!mounted) return;
    setState(() {
      _selectedMinutes = minutes;
      _soundEnabled = sound;
      _keepScreenOn = screenOn;
    });
  }

  void _onControllerChanged() {
    setState(() {});
    if (!_controller.isRunning) {
      WakelockPlus.disable();
    }
  }

  Future<void> _toggleSession() async {
    if (_controller.isRunning) {
      await _controller.stop();
      await WakelockPlus.disable();
      return;
    }

    setState(() => _starting = true);
    StartResult result;
    try {
      result = await _controller
          .start(
            totalDuration: _selectedMinutes == null
                ? null
                : Duration(minutes: _selectedMinutes!),
            soundEnabled: _soundEnabled,
          )
          .timeout(const Duration(seconds: 8));
    } catch (error) {
      // A failed or hung platform call (e.g. the OS rejecting the
      // foreground service) must never fail silently — show it instead of
      // leaving the button looking unresponsive.
      setState(() => _starting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('启动失败：$error')),
      );
      return;
    }
    setState(() => _starting = false);

    if (result == StartResult.notificationPermissionDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('需要通知权限才能在后台保持计时和提示音，请在系统设置中允许通知。'),
        ),
      );
      return;
    }

    if (_keepScreenOn) {
      await WakelockPlus.enable();
    }
  }

  String _formatMmSs(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final isRunning = _controller.isRunning;

    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('478 呼吸'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: isRunning ? null : _openSettingsSheet,
              tooltip: '设置',
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                BreathingCircle(
                  phase: state?.phase,
                  secondsRemaining: state?.secondsRemainingInPhase,
                ),
                const SizedBox(height: 32),
                Text(
                  isRunning
                      ? (state?.remainingSessionSeconds != null
                          ? '剩余 ${_formatMmSs(state!.remainingSessionSeconds!)}'
                          : '自由呼吸中 · 随时可停止')
                      : '吸气 4 秒 · 屏息 7 秒 · 呼气 8 秒',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (!isRunning)
                  DurationSelector(
                    selectedMinutes: _selectedMinutes,
                    onChanged: (minutes) {
                      setState(() => _selectedMinutes = minutes);
                      _settings.setLastMinutes(minutes);
                    },
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _starting ? null : _toggleSession,
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    // Always change something visible the instant the user
                    // taps, so "did my tap even register" is never in doubt.
                    child: _starting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(isRunning ? '结束' : '开始'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('提示音'),
                    subtitle: const Text('在切换吸气/屏息/呼气时播放提示音'),
                    value: _soundEnabled,
                    onChanged: (value) {
                      setSheetState(() {});
                      setState(() => _soundEnabled = value);
                      _settings.setSoundEnabled(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('训练时保持屏幕常亮'),
                    subtitle: const Text('关闭后可熄屏进行，后台仍会继续计时和提示音'),
                    value: _keepScreenOn,
                    onChanged: (value) {
                      setSheetState(() {});
                      setState(() => _keepScreenOn = value);
                      _settings.setKeepScreenOn(value);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }
}
