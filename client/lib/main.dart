import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/services/notification.service.dart';
import 'src/app.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// If you used the FlutterFire CLI, this file is generated at
// `lib/firebase_options.dart` and contains `DefaultFirebaseOptions`.
// Run `flutterfire configure` to generate it if missing.
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  await NotificationService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
