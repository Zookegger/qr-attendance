import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/screens/login/forgot_password_page.dart';
import 'package:qr_attendance_frontend/src/screens/login/reset_password_confirm_page.dart';
import 'package:qr_attendance_frontend/src/screens/splash/splash_screen.dart';
import 'screens/login/login_page.dart';
import 'screens/home/home_page.dart';
import 'screens/attendance/attendance_page.dart';
import 'screens/setup/server_setup_page.dart';
import 'screens/history/history_page.dart';
import 'screens/schedule/schedule_page.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      // Handle error
    }

    // Listen to link changes
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'qrattendance' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'];

      if (token != null && email != null) {
        _navigatorKey.currentState?.pushNamed(
          ResetPasswordConfirmPage.routeName,
          arguments: {'token': token, 'email': email},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'QR Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/forgot-password': (_) => const ForgotPasswordPage(),
        ResetPasswordConfirmPage.routeName: (_) => const ResetPasswordConfirmPage(),
        '/home': (_) => const HomePage(),
        '/attendance': (_) => const AttendancePage(),
        '/history': (_) => const HistoryPage(),
        '/schedule': (_) => const SchedulePage(),
        '/setup': (_) => const ServerSetupPage(),
      },
    );
  }
}
