import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';
import 'package:qr_attendance_frontend/src/services/auth.service.dart';
import 'package:qr_attendance_frontend/src/services/statistics.service.dart';
import 'package:qr_attendance_frontend/src/services/dashboard.service.dart';
import 'package:qr_attendance_frontend/src/services/report.service.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  final StatisticsService _statisticsService = StatisticsService();
  final DashboardService _dashboardService = DashboardService();
  final ReportService _reportService = ReportService();
  
  User? _user;
  List<TeamAttendanceDetail> _teamAttendance = [];
  TeamStats? _teamStats;
  bool _isLoading = true;
  StreamSubscription<Map<String, dynamic>>? _statsUpdateSub;
  DateTime _selectedDate = DateTime.now();
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _statsUpdateSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthenticationService().getCachedUser();
    if (mounted) {
      setState(() => _user = user);
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final teamStats = await _statisticsService.getTeamStats();
      final teamDetails = await _statisticsService.getTeamAttendanceDetails();
      
      if (mounted) {
        setState(() {
          _teamStats = teamStats;
          _teamAttendance = teamDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  void _setupRealtimeListener() {
    _dashboardService.connect();
    
    _statsUpdateSub?.cancel();
    _statsUpdateSub = _dashboardService.statsUpdateStream.listen((data) {
      debugPrint('Real-time stats update in analytics: $data');
      _loadData();
    });
  }

  Future<void> _downloadReport() async {
    setState(() => _isDownloading = true);
    
    try {
      final bytes = await _reportService.downloadAttendanceReport(
        month: _selectedDate.month,
        year: _selectedDate.year,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report downloaded: ${bytes.length} bytes',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error downloading report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Real-time Analytics'),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _isDownloading ? null : _downloadReport,
            tooltip: 'Download Excel Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConnectionStatus(),
                    const SizedBox(height: 16),
                    _buildTeamStatsCards(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Team Attendance Today'),
                    const SizedBox(height: 12),
                    _buildTeamAttendanceList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildConnectionStatus() {
    return StreamBuilder<bool>(
      stream: _dashboardService.connectionStream,
      initialData: _dashboardService.isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isConnected ? Colors.green : Colors.orange,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isConnected ? Icons.check_circle : Icons.wifi_off,
                color: isConnected ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'Real-time Updates Active' : 'Connecting...',
                style: TextStyle(
                  color: isConnected ? Colors.green.shade900 : Colors.orange.shade900,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamStatsCards() {
    if (_teamStats == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Present',
            _teamStats!.teamPresent.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Late',
            _teamStats!.teamLate.toString(),
            Icons.access_time,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Absent',
            _teamStats!.teamAbsent.toString(),
            Icons.cancel,
            Colors.red,
          ),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
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
            ),
          ),
        ],
      ),
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

  Widget _buildTeamAttendanceList() {
    if (_teamAttendance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No attendance records today',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _teamAttendance.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final detail = _teamAttendance[index];
        return _buildAttendanceCard(detail);
      },
    );
  }

  Widget _buildAttendanceCard(TeamAttendanceDetail detail) {
    Color statusColor;
    IconData statusIcon;
    
    switch (detail.status) {
      case 'PRESENT':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'LATE':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'ABSENT':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

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
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (detail.position != null)
                  Text(
                    detail.position!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                if (detail.department != null)
                  Text(
                    detail.department!,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (detail.isCheckedIn)
                      Icon(
                        Icons.radio_button_checked,
                        size: 12,
                        color: Colors.green,
                      ),
                    if (detail.isCheckedIn) const SizedBox(width: 4),
                    Text(
                      detail.status,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (detail.checkInTime != null)
                Text(
                  'In: ${detail.checkInTime}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              if (detail.checkOutTime != null)
                Text(
                  'Out: ${detail.checkOutTime}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
