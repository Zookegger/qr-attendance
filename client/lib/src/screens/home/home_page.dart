import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../../models/user.dart';
import '../../services/auth.service.dart';
import '../../services/admin.service.dart';

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
  final String checkOutTime = "--:--";
  final String totalTime = "1h 39m";
  final bool isCheckedIn = true; // Simulated status

  // Stats Data
  final int daysWorked = 22;
  final int daysOff = 1;
  final String overtimeHours = "4.5h";
  final int lateArrivals = 0;

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
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext dctx) {
                      return AlertDialog(
                        // Modern shape
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        // Icon for quick visual context
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                          size: 32,
                        ),
                        title: const Text('Confirm Logout'),
                        content: const Text(
                          'Are you sure you want to end your session?',
                          textAlign: TextAlign.center,
                        ),
                        actionsAlignment: MainAxisAlignment
                            .spaceEvenly, // Spreads buttons out
                        actions: [
                          // Neutral Cancel Button
                          TextButton(
                            onPressed: () => Navigator.pop(dctx),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          // Destructive Action Button (Red)
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dctx);
                              _handleLogout();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red, // The important part
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
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
            backgroundColor: Colors.indigo,
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
    debugPrint(_user?.role.name);

    // Using a slightly off-white background for better contrast
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _user?.role == UserRole.ADMIN || _user?.role == UserRole.MANAGER
          ? _buildManagerView()
          : _buildStaffView(),
      floatingActionButton: _buildAttendanceButton(context),
    );
  }

  Widget _buildStaffView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShiftCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Quick Actions"),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Monthly Overview"),
                  _buildStatsGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildManagerOverviewCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Management"),
                  const SizedBox(height: 24),
                  _buildManagerQuickActions(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Recent Requests"),
                  const SizedBox(height: 16),
                  _buildRecentRequests(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerOverviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Team Attendance",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTeamStat("Present", "18", Colors.green),
                _buildTeamStat("Late", "3", Colors.orange),
                _buildTeamStat("Absent", "2", Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to detailed attendance report
                },
                child: const Text("View Full Report"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamStat(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showUnbindDialog() {
    final userIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unbind Device"),
        content: TextField(
          controller: userIdController,
          decoration: const InputDecoration(labelText: "User ID"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final userId = userIdController.text.trim();
              if (userId.isNotEmpty) {
                try {
                  await AdminService().unbindDevice(userId);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Device unbound successfully"),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to unbind device: $e")),
                    );
                  }
                }
              }
            },
            child: const Text("Unbind"),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickActionButton(
          "Approvals",
          Icons.check_circle_outline,
          36,
          Colors.blue,
          () {},
        ),
        _buildQuickActionButton(
          "Employees",
          Icons.people_outline,
          36,
          Colors.purple,
          () {},
        ),
        _buildQuickActionButton(
          "Reports",
          Icons.bar_chart,
          36,
          Colors.orange,
          () {},
        ),
        _buildQuickActionButton(
          "Unbind",
          Icons.phonelink_erase,
          36,
          Colors.red,
          _showUnbindDialog,
        ),
      ],
    );
  }

  Widget _buildRecentRequests() {
    // Mock data for requests
    final requests = [
      {
        "name": "Sarah Connor",
        "type": "Leave Request",
        "date": "Today, 10:30 AM",
        "status": "Pending",
      },
      {
        "name": "John Smith",
        "type": "Overtime",
        "date": "Yesterday",
        "status": "Pending",
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (ctx, index) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final req = requests[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Text(
                  (req["name"] as String)[0],
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req["name"] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      req["type"] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    req["date"] as String,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      req["status"] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _openProfile,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: const NetworkImage(
                'https://i.pravatar.cc/150?img=12',
              ), // Placeholder
              child: _user?.name == null
                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Welcome back,",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildNotificationIcon(),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$notificationCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShiftCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Shift",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCheckedIn ? "Checked In" : "Not Checked In",
                      style: TextStyle(
                        color: isCheckedIn ? Colors.green : Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCheckedIn
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: isCheckedIn ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        totalTime,
                        style: TextStyle(
                          color: isCheckedIn ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeInfo("Check In", checkInTime, Icons.login),
                _buildTimeInfo("Check Out", checkOutTime, Icons.logout),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            Text(
              time,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D3436),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3436),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickActionButton(
          "History",
          Icons.history,
          42,
          Colors.blue,
          () => Navigator.pushNamed(context, '/history'),
        ),
        _buildQuickActionButton(
          "Schedule",
          Icons.calendar_month_outlined,
          42,
          Colors.purple,
          () => Navigator.pushNamed(context, '/schedule'),
        ),
        _buildQuickActionButton(
          "Forms",
          Icons.description,
          42,
          Colors.green,
          () => Navigator.pushNamed(context, '/forms'),
        ),
        _buildQuickActionButton(
          "More",
          Icons.grid_view_rounded,
          42,
          Colors.orange,
          () {},
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    double iconSize,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: <Widget>[
        IconButton(
          onPressed: onTap,
          icon: Icon(icon),
          iconSize: iconSize,
          color: color,
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),

            backgroundColor: WidgetStateProperty.all(
              color.withValues(alpha: 0.08),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(label),
      ],
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
        _buildStatCard(
          "Days Worked",
          "$daysWorked",
          Icons.work_outline,
          Colors.blue,
        ),
        _buildStatCard(
          "Days Off",
          "$daysOff",
          Icons.beach_access_outlined,
          Colors.orange,
        ),
        _buildStatCard(
          "Overtime",
          overtimeHours,
          Icons.access_time,
          Colors.purple,
        ),
        _buildStatCard(
          "Late Arrival",
          "$lateArrivals",
          Icons.warning_amber_rounded,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              if (label == "Late Arrival" && int.parse(value) > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Alert",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        // Open the attendance dashboard; scanner and manual entry
        // are handled from there. Do not force permissions on entry.
        Navigator.pushNamed(context, '/attendance');
      },
      icon: const Icon(Icons.punch_clock_outlined),
      label: const Text('Attendance'),
      // backgroundColor: const Color(0xFF4A00E0),
      elevation: 6,
    );
  }
}
