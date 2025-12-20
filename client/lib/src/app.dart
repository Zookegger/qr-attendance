import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/screens/splash/splash_screen.dart';
import 'screens/login/login_page.dart';
import 'screens/home/home_page.dart';
import 'screens/attendance/scan_page.dart';
import 'screens/setup/server_setup_page.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/scan': (_) => const ScanPage(),
        '/setup': (_) => const ServerSetupPage(),
      },
    );
  }
}
