import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_attendance_frontend/src/screens/form/create_request_page.dart';
import 'dart:async';

import '../../models/user.dart';
import '../../services/auth.service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user;
  int notificationCount = 0;

  // Shift Data
  final String checkInTime = "08:02 AM";
  final String checkOutTime = "--";
  final String totalTime = "1h 39m";

  // Stats Data
  final int daysWorked = 30;
  final int daysOff = 1;
  final String overtimeHours = "4h";
  final int lateArrivals = 3;

  StreamSubscription<RemoteMessage>? _onMessageSub;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _setupNotificationListener();
  }

  Future<void> _handleLogout() async {
    await AuthenticationService().logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  void _openProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile screen is not available yet.')),
    );
  }

  Future<void> _loadUser() async {
    final cached = await AuthenticationService().getCachedUser();
    if (mounted) {
      setState(() => _user = cached);
    }
  }

  void _setupNotificationListener() {
    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        setState(() {
          notificationCount++;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.title ?? "New Notification"),
            action: SnackBarAction(label: 'View', onPressed: () {}),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildQuickActions(),
              const SizedBox(height: 30),
              _buildShiftCard(),
              const SizedBox(height: 30),
              _buildScanButton(context),
              const SizedBox(height: 30),
              _buildStatsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'profile':
                _openProfile();
                break;
              case 'logout':
                _handleLogout();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'profile', child: Text('View profile')),
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.purple.shade100,
            child: const Icon(Icons.person_outline, color: Colors.purple),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "Hello ${_user?.name ?? 'User'}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Stack(
          children: [
            const Icon(Icons.notifications_none, size: 30),
            if (notificationCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$notificationCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          Icons.bar_chart,
          "History",
          Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/history'),
        ),
        _buildActionButton(
          Icons.calendar_month,
          "Schedule",
          Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/schedule'),
        ),
        _buildActionButton(
          Icons.receipt_long,
          "Requests",
          Colors.orange,
          onTap: () {
            if (_user == null) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateRequestPage(user: _user!),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildShiftCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[100] ?? Colors.grey.withAlpha(26),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                "Today's shift",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Icon(Icons.calendar_today, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeRow("Check-in: $checkInTime"),
          const SizedBox(height: 8),
          _buildTimeRow("Check-out: $checkOutTime"),
          const SizedBox(height: 16),
          Text(
            "Total time: $totalTime",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String text) {
    return Row(
      children: [
        const Icon(Icons.access_time, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () async {
          Map<Permission, PermissionStatus> statuses = await [
            Permission.camera,
            Permission.location,
          ].request();

          if (statuses[Permission.camera]!.isGranted &&
              statuses[Permission.location]!.isGranted) {
            if (context.mounted) {
              Navigator.pushNamed(context, '/scan');
            }
          } else {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Permission needed"),
                  content: const Text(
                    "Camera and Location permissions are required to check in.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Đóng"),
                    ),
                    TextButton(
                      onPressed: () => openAppSettings(),
                      child: const Text("Cài đặt"),
                    ),
                  ],
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A4A4A), // Dark grey
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.white),
            SizedBox(width: 12),
            Text(
              "Scan QR to check in",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(Icons.access_time, daysWorked.toString(), "Days worked"),
        _buildStatCard(Icons.access_time, daysOff.toString(), "Days off"),
        _buildStatCard(Icons.access_time, overtimeHours, "Overtime"),
        _buildStatCard(
          Icons.access_time,
          lateArrivals.toString(),
          "Late arrivals",
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(13),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
