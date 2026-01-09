import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_attendance_frontend/src/services/auth.service.dart';

class KioskActiveGuard extends StatefulWidget {
  final Widget child;
  final int startHour;
  final int endHour;

  const KioskActiveGuard({
    super.key,
    required this.child,
    this.startHour = 6,
    this.endHour = 22,
  });

  @override
  State<KioskActiveGuard> createState() => _KioskActiveGuardState();
}

class _KioskActiveGuardState extends State<KioskActiveGuard> {
  Timer? _timer;
  bool _isLocked = false;
  final TextEditingController _passwordController = TextEditingController();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // 1. Hide the Status Bar and Navigation Buttons (Home/Back/Overview)
    // "immersiveSticky" means if they swipe to reveal them, they disappear again automatically.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _checkTime();
    _startSyncedTimer();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _timer?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final shouldLock = hour < widget.startHour || hour >= widget.endHour;

    if (shouldLock != _isLocked) {
      setState(() => _isLocked = shouldLock);
    }
  }

  void _startSyncedTimer() {
    final now = DateTime.now();
    // Calculate seconds remaining until the next full minute
    final secondsUntilNextMinute = 60 - now.second;

    // 1. Wait for the precise moment the minute changes
    _timer = Timer(Duration(seconds: secondsUntilNextMinute), () {
      // 2. Double-check we are still mounted before running logic
      if (!mounted) return;

      // 3. perform the check at xx:xx:00
      _checkTime();

      // 4. NOW switch to a standard 1-minute periodic timer
      // It will now drift very little because it started at :00
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => _checkTime());
    });
  }

  Future<void> _handleUnlock() async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Station'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your password to exit Kiosk mode.'),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _passwordController.text),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (password != null && password.isNotEmpty) {
      setState(() => _isAuthenticating = true);
      try {
        final authService = AuthenticationService();
        final user = await authService.getCachedUser();
        if (user != null) {
          // Verify password without creating new session
          final isValid = await authService.verifyPassword(
            user.email,
            password,
          );

          if (isValid) {
            if (mounted) {
              Navigator.of(context).pop(); // Exit Kiosk Page
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid password.')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not verify user identity.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unlock failed: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isAuthenticating = false);
          _passwordController.clear();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // onPopInvoked: (didPop) {
      // },
      child: Stack(
        children: [
          widget.child,

          if (_isLocked)
            Container(
              color: Colors.black.withValues(alpha: 0.95),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.nightlight_round,
                      color: Colors.blueGrey,
                      size: 80,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Shift Ended",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Station is locked until ${widget.startHour}:00",
                      style: const TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                    const SizedBox(height: 48),
                    if (_isAuthenticating)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton.icon(
                        onPressed: _handleUnlock,
                        icon: const Icon(Icons.lock_open),
                        label: const Text("Unlock Station"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
