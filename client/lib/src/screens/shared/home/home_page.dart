import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/models/notification.dart';
import 'package:qr_attendance_frontend/src/models/request.dart';
import 'package:qr_attendance_frontend/src/screens/shared/NotificationScreen.dart';
import 'dart:async';

import 'package:qr_attendance_frontend/src/models/user.dart';
import 'package:qr_attendance_frontend/src/services/auth.service.dart';
import 'package:qr_attendance_frontend/src/services/request.service.dart';
import 'package:qr_attendance_frontend/src/services/statistics.service.dart';
import 'package:qr_attendance_frontend/src/services/dashboard.service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<AppNotification> notifications = [];

  User? _user;
  int notificationCount = 0;
  List<Request> _recentRequests = [];
  final RequestService _requestService = RequestService();
  final StatisticsService _statisticsService = StatisticsService();
  final DashboardService _dashboardService = DashboardService();
  StreamSubscription<Map<String, dynamic>>? _statsUpdateSub;

  // Shift Data (Defaults)
  String checkInTime = "--:--";
  String checkOutTime = "--:--";
  String totalTime = "--:--";
  bool isCheckedIn = false;

  // Stats Data (Defaults)
  int daysWorked = 0;
  int daysOff = 0;
  String overtimeHours = "0h";
  int lateArrivals = 0;

  // Team Data (Defaults)
  int teamPresent = 0;
  int teamLate = 0;
  int teamAbsent = 0;

  StreamSubscription<RemoteMessage>? _onMessageSub;

  @override
  void initState() {
    super.initState();

    _loadUser();
    _setupNotificationListener();
    _setupStatsListener();
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                        actionsAlignment: MainAxisAlignment.spaceEvenly,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dctx),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dctx);
                              _handleLogout();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
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
      if (_user != null) {
        // Load shift and stats data
        _loadShiftData();
        _loadStats();
        
        if (_user?.role == UserRole.ADMIN || _user?.role == UserRole.MANAGER) {
          _loadRecentRequests();
          _loadTeamStats();
        }
      }
    }
  }

  Future<void> _loadRecentRequests() async {
    try {
      final requests = await _requestService.listRequests();
      if (mounted) {
        setState(() {
          _recentRequests = requests.take(5).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading requests: $e');
    }
  }

  Future<void> _loadShiftData() async {
    if (_user == null) return;
    
    try {
      final shift = await _statisticsService.getTodayShift(_user!.id);
      if (mounted) {
        setState(() {
          checkInTime = shift.checkInTime ?? '--:--';
          checkOutTime = shift.checkOutTime ?? '--:--';
          totalTime = shift.totalTime;
          isCheckedIn = shift.isCheckedIn;
        });
      }
    } catch (e) {
      debugPrint('Error loading shift data: $e');
    }
  }

  Future<void> _loadStats() async {
    if (_user == null) return;
    
    try {
      final stats = await _statisticsService.getPersonalStats(_user!.id);
      if (mounted) {
        setState(() {
          daysWorked = stats.daysWorked;
          daysOff = stats.daysOff;
          overtimeHours = stats.overtimeHours;
          lateArrivals = stats.lateArrivals;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadTeamStats() async {
    try {
      final stats = await _statisticsService.getTeamStats();
      if (mounted) {
        setState(() {
          teamPresent = stats.teamPresent;
          teamLate = stats.teamLate;
          teamAbsent = stats.teamAbsent;
        });
      }
    } catch (e) {
      debugPrint('Error loading team stats: $e');
    }
  }

  void _setupStatsListener() {
    _dashboardService.connect();
    
    _statsUpdateSub?.cancel();
    _statsUpdateSub = _dashboardService.statsUpdateStream.listen((data) {
      debugPrint('Stats update received in home page: $data');
      
      // Reload data when stats update
      if (_user != null) {
        _loadShiftData();
        _loadStats();
        
        if (_user?.role == UserRole.ADMIN || _user?.role == UserRole.MANAGER) {
          _loadTeamStats();
        }
      }
    });
  }

  Future<void> _loadRecentRequests() async {
    try {
      final requests = await _requestService.listRequests();
      if (mounted) {
        setState(() {
          _recentRequests = requests.take(5).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading requests: $e');
    }
  }

  void _setupNotificationListener() {
    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final noti = AppNotification(
        title: message.notification?.title ?? "Notification",
        body: message.notification?.body ?? "",
        time: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          notifications.insert(0, noti);
          notificationCount = notifications.length;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(noti.title),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _statsUpdateSub?.cancel();
    _dashboardService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildShiftCard(),
                  const SizedBox(height: 24),
                  _buildManagerOverviewCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Actions"),
                  _buildManagerQuickActions(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("My Stats"),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Recent Requests"),
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
                _buildTeamStat("Present", "$teamPresent", Colors.green),
                _buildTeamStat("Late", "$teamLate", Colors.orange),
                _buildTeamStat("Absent", "$teamAbsent", Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin/analytics');
                  },
                  child: const Text("View Full Report"),
                ),
              ],
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

  Widget _buildManagerQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.1,
      children: [
        // Admin Features (Renamed for brevity)
        _buildQuickActionButton(
          "Requests",
          Icons.check_circle_outline,
          48,
          Colors.blue,
          () => Navigator.pushNamed(context, '/admin/requests'),
        ),
        _buildQuickActionButton(
          "Staff",
          Icons.people_outline,
          48,
          Colors.purple,
          () => Navigator.pushNamed(context, '/employees'),
        ),
        _buildQuickActionButton(
          "Schedules",
          Icons.calendar_month,
          48,
          Colors.teal,
          () => Navigator.pushNamed(context, '/admin/roster'),
        ),
        _buildQuickActionButton(
          "Shifts",
          Icons.access_time_filled,
          48,
          Colors.teal,
          () => Navigator.pushNamed(context, '/admin/workshifts'),
        ),
        _buildQuickActionButton(
          "Offices",
          Icons.business,
          48,
          Colors.indigo,
          () => Navigator.pushNamed(context, '/admin/office'),
        ),
        _buildQuickActionButton(
          "Kiosk",
          Icons.qr_code_2,
          48,
          Colors.orange,
          () => Navigator.pushNamed(context, '/admin/kiosk'),
        ),
        // User Features (Merged & Renamed)
        _buildQuickActionButton(
          "My History",
          Icons.history,
          48,
          Colors.blueGrey,
          () => Navigator.pushNamed(context, '/history'),
        ),
        _buildQuickActionButton(
          "My Schedules",
          Icons.calendar_today,
          48,
          Colors.deepPurple,
          () => Navigator.pushNamed(context, '/schedule'),
        ),
        _buildQuickActionButton(
          "My Forms",
          Icons.description,
          48,
          Colors.green,
          () => Navigator.pushNamed(context, '/user/requests'),
        ),
      ],
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} years ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} months ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildRecentRequests() {
    if (_recentRequests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("No recent requests")],
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentRequests.length,

        separatorBuilder: (ctx, index) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final req = _recentRequests[index];
          final name = req.userName ?? 'Unknown';

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
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        req.type.toTextString(),
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
                      _timeAgo(req.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          req.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        req.status.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(req.status),
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
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.APPROVED:
        return Colors.green;
      case RequestStatus.REJECTED:
        return Colors.red;
      case RequestStatus.PENDING:
        return Colors.orange;
    }
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    NotificationScreen(notifications: notifications),
              ),
            );
          },
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
          () => Navigator.pushNamed(context, '/user/requests'),
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
    return SizedBox(
      height: 100,
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
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
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            style: const TextStyle(
              fontSize: 14,
              height: 1.75, // Tighter line height helps fit more text
            ),
          ),
        ],
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