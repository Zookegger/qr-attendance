import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';
import 'package:qr_attendance_frontend/src/models/workshift.dart';
import 'package:qr_attendance_frontend/src/screens/admin/employees/employee_detail_page.dart';
import 'package:qr_attendance_frontend/src/screens/admin/employees/employee_form_page.dart';
import 'package:qr_attendance_frontend/src/screens/admin/employees/list_employee_page.dart';
import 'package:qr_attendance_frontend/src/screens/admin/requests/admin_request_list_page.dart';
import 'package:qr_attendance_frontend/src/screens/shared/schedule/schedule_page.dart';
import 'package:qr_attendance_frontend/src/screens/admin/schedule/manage_schedule_page.dart';
import 'package:qr_attendance_frontend/src/screens/admin/workshift/workshift_list_page.dart';
import 'package:qr_attendance_frontend/src/screens/admin/workshift/workshift.form_page.dart';
import 'package:qr_attendance_frontend/src/screens/admin/kiosk/kiosk_page.dart';
import 'package:qr_attendance_frontend/src/screens/admin/schedule/roster_page.dart';
import 'package:qr_attendance_frontend/src/screens/admin/office/office_config_page.dart';

// Screens
import 'package:qr_attendance_frontend/src/screens/shared/splash/splash_screen.dart';
import 'package:qr_attendance_frontend/src/screens/shared/login/forgot_password_page.dart';
import 'package:qr_attendance_frontend/src/screens/shared/login/reset_password_confirm_page.dart';
import 'package:qr_attendance_frontend/src/screens/user/requests/request_form_page.dart';
import 'package:qr_attendance_frontend/src/screens/user/requests/request_list_page.dart';
import 'package:qr_attendance_frontend/src/theme/app_theme.dart';
import 'package:qr_attendance_frontend/src/widgets/connection_status_overlay.dart';
import 'screens/shared/login/login_page.dart';
import 'screens/shared/home/home_page.dart';
import 'screens/shared/attendance/attendance_page.dart';
import 'screens/shared/setup/server_setup_page.dart';
import 'screens/shared/history/history_page.dart';
import 'screens/shared/profile/profile.dart';

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
      builder: (context, child) {
        return ConnectionStatusOverlay(child: child!);
      },
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
        '/profile': (_) => const ProfilePage(),
        '/employees': (_) => const EmployeeListPage(),

        // Workshifts
        '/admin/workshifts': (_) => const WorkshiftListPage(),

        // Requests
        '/user/requests': (_) => const RequestListPage(),
        '/user/requests/form': (_) => const RequestFormPage(),
        '/admin/requests': (_) => const AdminRequestListPage(),

        '/admin/kiosk': (_) => const KioskPage(),
        '/admin/roster': (_) => const RosterPage(),
        '/admin/office': (_) => const OfficeConfigPage(),
      },

      onGenerateRoute: (settings) {
        // 1. Employee FORM (Create or Edit)
        // Accepts User? (null = create, user object = edit)
        if (settings.name == '/employee/form') {
          final user = settings.arguments as User?;
          return MaterialPageRoute(
            builder: (_) => EmployeeFormPage(user: user),
          );
        }

        // 2. Employee DETAILS (View Info / Unbind)
        // Accepts required User object
        if (settings.name == '/employee/details') {
          if (settings.arguments is User) {
            final user = settings.arguments as User;
            return MaterialPageRoute(
              builder: (_) => EmployeeDetailsPage(user: user),
            );
          }
          // Fallback if arguments are missing/wrong
          return _errorRoute();
        }

        // 3. Employee SCHEDULE
        // Accepts required User object
        if (settings.name == '/admin/schedule') {
          if (settings.arguments is User) {
            final user = settings.arguments as User;
            return MaterialPageRoute(
              builder: (_) => ManageEmployeeSchedulePage(user: user),
            );
          }
          return _errorRoute();
        }

        // 4. Workshift FORM (Create or Edit)
        // Accepts Workshift? (null = create, workshift object = edit)
        if (settings.name == '/admin/workshift/form') {
          final workshift = settings.arguments as Workshift?;
          return MaterialPageRoute(
            builder: (_) => WorkshiftFormPage(workshift: workshift),
          );
        }

        return null; // Standard 'Route Not Found' behavior
      },
    );
  }

  MaterialPageRoute _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Invalid navigation arguments")),
      ),
    );
  }
}
