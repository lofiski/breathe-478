import 'package:flutter/material.dart';

import 'services/breathing_controller.dart';
import 'ui/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BreathingController.initPlatform();
  runApp(const BreatheApp());
}

class BreatheApp extends StatelessWidget {
  const BreatheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '478 呼吸',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
