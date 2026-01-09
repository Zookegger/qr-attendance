import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_attendance_frontend/src/blocs/attendance/attendance_bloc.dart';
import 'package:qr_attendance_frontend/src/blocs/auth/auth_bloc.dart';
import 'package:qr_attendance_frontend/src/blocs/request/request_bloc.dart';
import 'package:qr_attendance_frontend/src/blocs/schedule/schedule_bloc.dart';
import 'package:qr_attendance_frontend/src/services/config.service.dart';
import 'package:qr_attendance_frontend/src/services/notification.service.dart';
import 'src/app.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await ConfigService().init();

      runApp(const MyApp());

      // Don't block the first frame on notification setup.
      unawaited(NotificationService().init());
    },
    (error, stack) {
      // Handle uncaught errors safely
      log('Uncaught error: $error', stackTrace: stack);
      // You can also show an error screen or report to a service here
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
        ),
        BlocProvider<ScheduleBloc>(
          create: (context) => ScheduleBloc(),
        ),
        BlocProvider<RequestBloc>(
          create: (context) => RequestBloc(),
        ),
        BlocProvider<AttendanceBloc>(
          create: (context) => AttendanceBloc(),
        ),
      ],
      child: const App(),
    );
  }
}
