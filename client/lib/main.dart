import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/services/config.service.dart';
import 'package:qr_attendance_frontend/src/services/notification.service.dart';
import 'src/app.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await ConfigService().init();

    runApp(const MyApp());

    // Don't block the first frame on notification setup.
    unawaited(NotificationService().init());
  }, (error, stack) {
    // Handle uncaught errors safely
    log('Uncaught error: $error', stackTrace: stack);
    // You can also show an error screen or report to a service here
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
