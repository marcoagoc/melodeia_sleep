import 'package:flutter/material.dart';

import '../features/auth/firebase_bootstrap.dart';
import '../features/session/presentation/home_screen.dart';

class MelodeiaSleepApp extends StatelessWidget {
  const MelodeiaSleepApp({required this.firebaseStatus, super.key});

  final FirebaseBootstrapStatus firebaseStatus;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff6eb6d6),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Melodeia Sleep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xff030712),
        sliderTheme: SliderThemeData(
          activeTrackColor: scheme.primary,
          inactiveTrackColor: scheme.surfaceContainerHighest,
          thumbColor: scheme.primary,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(firebaseStatus: firebaseStatus),
    );
  }
}
