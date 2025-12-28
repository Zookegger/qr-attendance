import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

// Screens
import 'package:qr_attendance_frontend/src/screens/splash/splash_screen.dart';
import 'package:qr_attendance_frontend/src/screens/login/forgot_password_page.dart';
import 'package:qr_attendance_frontend/src/screens/login/reset_password_confirm_page.dart';
import 'package:qr_attendance_frontend/src/screens/form/create_request_page.dart'; // From snippet 2

// Relative imports (kept as per your existing structure)
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

    // Check initial link (if app was launched via link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      // Handle error gracefully or log it
      debugPrint("Deep Link Init Error: $e");
    }

    // Listen to link changes (if app is already running in background)
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
        // Base
        '/splash': (_) => const SplashPage(),
        '/setup': (_) => const ServerSetupPage(),

        // Auth
        '/login': (_) => const LoginPage(),
        '/forgot-password': (_) => const ForgotPasswordPage(),
        ResetPasswordConfirmPage.routeName: (_) =>
            const ResetPasswordConfirmPage(),

        // Main
        '/home': (_) => const HomePage(),
        '/attendance': (_) => const AttendancePage(),
        '/history': (_) => const HistoryPage(),
        '/schedule': (_) => const SchedulePage(),

        // Requests
        '/form': (_) => const CreateRequestPage(),
      },
    );
  }
}
