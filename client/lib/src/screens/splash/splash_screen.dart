import 'package:flutter/material.dart';
import '../../services/config.service.dart';
import '../../services/auth.service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Ensure navigation happens after the build phase is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkState();
    });
  }

  Future<void> _checkState() async {
    if (!mounted) return;

    if (!ConfigService().hasBaseUrl) {
      Navigator.of(context).pushReplacementNamed('/setup');
      return;
    }

    // Optional: Check if user is already logged in?
    final user = await AuthenticationService().getCachedUser();

    if (!mounted) return;

    if (user != null) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
