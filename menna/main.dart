import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../lib/camera_screen.dart';
import '../lib/history_screen.dart';

import '../lib/recorder_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alerto',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/camera': (context) => const CameraScreen(),
        '/history': (context) => const HistoryScreen(),

        '/dashboard': (context) => const RecorderDashboardScreen(),
      },
    );
  }
}