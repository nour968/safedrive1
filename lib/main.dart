import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:untitled1/profile_screen.dart';
import 'package:untitled1/signup_screen.dart';
import 'package:untitled1/login_screen.dart';

import 'services/socket_service.dart';

// Screens
import 'Splash_Screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'camera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // START SOCKET SERVICE
  SocketService.connect();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale locale) {
    final _MyAppState? state =
    context.findAncestorStateOfType<_MyAppState>();

    state?.setLocale(locale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'Alerto',

      // LOCALIZATION
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      locale: _locale,

      // ROUTES
      initialRoute: '/',

      routes: {

        '/': (context) => const WelcomeScreen(),

        '/home': (context) => const HomeScreen(),

        '/camera': (context) => const CameraScreen(),

        '/profile': (context) => const ProfileScreen(),

        '/signup': (context) => const SignUpScreen(),

        '/login': (context) => const LoginScreen(),

        '/history': (context) => const HistoryScreen(),

        '/splash': (context) => const WelcomeScreen(),
      },
    );
  }
}
