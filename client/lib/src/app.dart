import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/screens/login/forgot_password_page.dart';
import 'package:qr_attendance_frontend/src/screens/splash/splash_screen.dart';
import 'screens/login/login_page.dart';
import 'screens/home/home_page.dart';
import 'screens/attendance/attendance_page.dart';
import 'screens/setup/server_setup_page.dart';
import 'screens/history/history_page.dart';
import 'screens/schedule/schedule_page.dart';
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
        '/forgot-password': (_) => const ForgotPasswordPage(),
        '/home': (_) => const HomePage(),
        '/attendance': (_) => const AttendancePage(),
        '/history': (_) => const HistoryPage(),
        '/schedule': (_) => const SchedulePage(),
        '/setup': (_) => const ServerSetupPage(),
      },
    );
  }
}
