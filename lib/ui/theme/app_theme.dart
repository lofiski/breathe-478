import 'package:flutter/material.dart';

import '../../core/breath_phase.dart';

/// Calm, minimal palette. Each phase gets its own accent so the circle and
/// background can drift between colors instead of relying on motion alone.
class PhaseColors {
  static const inhale = Color(0xFF5EEAD4); // teal
  static const hold = Color(0xFFFCD34D); // warm amber
  static const exhale = Color(0xFF93C5FD); // soft blue
  static const idle = Color(0xFF64748B); // slate

  static Color of(BreathPhase? phase) => switch (phase) {
        BreathPhase.inhale => inhale,
        BreathPhase.hold => hold,
        BreathPhase.exhale => exhale,
        null => idle,
      };
}

class AppTheme {
  static ThemeData get dark {
    const background = Color(0xFF0B1120);
    final scheme = ColorScheme.fromSeed(
      seedColor: PhaseColors.inhale,
      brightness: Brightness.dark,
      surface: background,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        displayLarge: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  static ThemeData get light {
    const background = Color(0xFFF8FAFC);
    final scheme = ColorScheme.fromSeed(
      seedColor: PhaseColors.exhale,
      brightness: Brightness.light,
      surface: background,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
    );
  }
}
