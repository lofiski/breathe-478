/// One stage of the 4-7-8 breathing cycle.
enum BreathPhase {
  inhale(seconds: 4, label: '吸气', soundAsset: 'sounds/inhale.wav'),
  hold(seconds: 7, label: '屏息', soundAsset: 'sounds/hold.wav'),
  exhale(seconds: 8, label: '呼气', soundAsset: 'sounds/exhale.wav');

  const BreathPhase({
    required this.seconds,
    required this.label,
    required this.soundAsset,
  });

  final int seconds;
  final String label;
  final String soundAsset;
}
