import 'package:audioplayers/audioplayers.dart';

import '../core/breath_phase.dart';

/// Plays the short phase-change cues from the UI isolate.
///
/// Each clip gets its own preloaded player so a cue starts effectively
/// instantly instead of paying asset-decode latency at the moment the phase
/// flips.
class CuePlayer {
  static const sessionEndAsset = 'sounds/session_end.wav';

  final Map<String, AudioPlayer> _players = {};
  bool _loaded = false;

  Future<void> preload() async {
    if (_loaded) return;
    _loaded = true;

    final assets = <String>[
      for (final phase in BreathPhase.values) phase.soundAsset,
      sessionEndAsset,
    ];

    for (final asset in assets) {
      try {
        final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(asset));
        await player.setVolume(0.7);
        _players[asset] = player;
      } catch (_) {
        // A cue that fails to load must never block the session itself.
      }
    }
  }

  Future<void> play(String asset) async {
    final player = _players[asset];
    if (player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {
      // Audio problems must never interrupt the breathing timer.
    }
  }

  Future<void> dispose() async {
    for (final player in _players.values) {
      try {
        await player.dispose();
      } catch (_) {
        // Best effort.
      }
    }
    _players.clear();
    _loaded = false;
  }
}
