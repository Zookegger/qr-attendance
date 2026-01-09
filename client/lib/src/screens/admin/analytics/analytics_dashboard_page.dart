import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:qr_attendance_frontend/src/models/attendance_record.dart';
import 'package:qr_attendance_frontend/src/services/auth.service.dart';
import 'package:qr_attendance_frontend/src/services/attendance.service.dart';
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
  final AttendanceService _attendanceService = AttendanceService();
  final StatisticsService _statisticsService = StatisticsService();
  final DashboardService _dashboardService = DashboardService();
  final ReportService _reportService = ReportService();
  final AuthenticationService _authService = AuthenticationService();

  // Date range selection
  DateTimeRange? _dateRange;
  DateTime get _startDate =>
      _dateRange?.start ?? DateTime.now().subtract(const Duration(days: 30));
  DateTime get _endDate => _dateRange?.end ?? DateTime.now();

  // Data storage
  List<AttendanceRecord> _allRecords = [];
  Map<String, List<AttendanceRecord>> _recordsByDate = {};
  List<TeamAttendanceDetail> _teamDetails = [];
  bool _isLoading = false;
  bool _isDownloading = false;
  StreamSubscription<Map<String, dynamic>>? _statsUpdateSub;

  // Computed summary metrics
  int get _totalCheckIns =>
      _allRecords.where((r) => r.checkInTime != null).length;
  int get _totalCheckOuts =>
      _allRecords.where((r) => r.checkOutTime != null).length;
  int get _totalPresent =>
      _allRecords.where((r) => r.status == 'PRESENT').length;
  int get _totalLate => _allRecords.where((r) => r.status == 'LATE').length;
  int get _totalAbsent => _allRecords.where((r) => r.status == 'ABSENT').length;

  double get _totalWorkingHours {
    double total = 0;
    for (var record in _allRecords) {
      if (record.checkInTime != null && record.checkOutTime != null) {
        final duration = record.checkOutTime!.difference(record.checkInTime!);
        total += duration.inMinutes / 60.0;
      }
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    // Set default date range to last 30 days
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _setupRealtimeListener();
    _loadData();
  }

  @override
  void dispose() {
    _statsUpdateSub?.cancel();
    super.dispose();
  }

  void _setupRealtimeListener() {
    _dashboardService.connect();

    _statsUpdateSub?.cancel();
    _statsUpdateSub = _dashboardService.statsUpdateStream.listen((data) {
      debugPrint('Real-time stats update in analytics: $data');
      // Reload data when real-time updates occur
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = await _authService.getCachedUser();
      if (user == null) throw Exception('User not authenticated');

      _allRecords = [];
      _recordsByDate = {};

      // Fetch attendance history for the selected date range
      // Iterate through months using DateTime parameter
      DateTime current = DateTime(_startDate.year, _startDate.month);
      final end = DateTime(_endDate.year, _endDate.month);

      while (current.isBefore(end) ||
          (current.year == end.year && current.month == end.month)) {
        try {
          // Use DateTime parameter as per the service signature
          final records = await _attendanceService.fetchHistory(
            month: DateTime(current.year, current.month),
          );

          // Filter records by actual date range
          final filtered = records.where((r) {
            return !r.date.isBefore(_startDate) &&
                !r.date.isAfter(_endDate.add(const Duration(days: 1)));
          }).toList();

          _allRecords.addAll(filtered);

          // Group by date
          for (var record in filtered) {
            final dateKey = DateFormat('yyyy-MM-dd').format(record.date);
            _recordsByDate.putIfAbsent(dateKey, () => []).add(record);
          }
        } catch (e) {
          debugPrint(
            'Error fetching records for ${current.year}-${current.month}: $e',
          );
        }

        current = DateTime(current.year, current.month + 1);
      }

      // Fetch team details (always current/latest)
      try {
        _teamDetails = await _statisticsService.getTeamAttendanceDetails();
      } catch (e) {
        debugPrint('Error fetching team details: $e');
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() => _dateRange = picked);
      _loadData();
    }
  }

  Future<void> _downloadReport() async {
    setState(() => _isDownloading = true);

    try {
      final midDate = DateTime(
        (_startDate.year + _endDate.year) ~/ 2,
        (_startDate.month + _endDate.month) ~/ 2,
      );

      final bytes = await _reportService.downloadAttendanceReport(
        month: midDate.month,
        year: midDate.year,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report downloaded: ${bytes.length} bytes'),
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
        title: const Text('Analytics & Reports'),
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
      body: _isLoading && _allRecords.isEmpty
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
                    _buildDateRangeSelector(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Summary Metrics'),
                    const SizedBox(height: 12),
                    _buildSummaryMetrics(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Trends & Charts'),
                    const SizedBox(height: 12),
                    _buildChartsSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Team Attendance Summary'),
                    const SizedBox(height: 12),
                    _buildTeamAttendanceDetails(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Detailed Records'),
                    const SizedBox(height: 12),
                    _buildDetailedTable(),
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
                  color: isConnected
                      ? Colors.green.shade900
                      : Colors.orange.shade900,
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

  Widget _buildDateRangeSelector() {
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
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Color(0xFF2D3436)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.edit_calendar, size: 18),
            label: const Text('Change'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildSummaryMetrics() {
    if (_allRecords.isEmpty) {
      return _buildEmptyState('No data available for the selected period');
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Check-ins',
                _totalCheckIns.toString(),
                Icons.login,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Check-outs',
                _totalCheckOuts.toString(),
                Icons.logout,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Present',
                _totalPresent.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Late',
                _totalLate.toString(),
                Icons.access_time,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Absent',
                _totalAbsent.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          'Total Working Hours',
          '${_totalWorkingHours.toStringAsFixed(1)} hrs',
          Icons.schedule,
          Colors.indigo,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    if (_allRecords.isEmpty) {
      return _buildEmptyState('No data available for charts');
    }

    return Column(
      children: [
        _buildStatusPieChart(),
        const SizedBox(height: 16),
        _buildDailyTrendChart(),
      ],
    );
  }

  Widget _buildTeamAttendanceDetails() {
    if (_teamDetails.isEmpty) {
      return _buildEmptyState('No team attendance data available');
    }

    return Container(
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
          // Table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Department',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Check-in',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _teamDetails.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final detail = _teamDetails[index];
              final statusColor = detail.isCheckedIn ? Colors.green : Colors.orange;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.userName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (detail.position != null)
                            Text(
                              detail.position!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        detail.department ?? '--',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          detail.status,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        detail.checkInTime ?? '--:--',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPieChart() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: _totalPresent.toDouble(),
                    title: '$_totalPresent',
                    color: Colors.green,
                    radius: 80,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  PieChartSectionData(
                    value: _totalLate.toDouble(),
                    title: '$_totalLate',
                    color: Colors.orange,
                    radius: 80,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  PieChartSectionData(
                    value: _totalAbsent.toDouble(),
                    title: '$_totalAbsent',
                    color: Colors.red,
                    radius: 80,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Present', Colors.green),
              _buildLegendItem('Late', Colors.orange),
              _buildLegendItem('Absent', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildDailyTrendChart() {
    // Group records by date and count statuses
    final dateKeys = _recordsByDate.keys.toList()..sort();
    if (dateKeys.length < 2) {
      return _buildEmptyState('Need at least 2 days of data for trend chart');
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Attendance Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dateKeys.length) {
                          final date = DateTime.parse(dateKeys[index]);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: dateKeys.asMap().entries.map((entry) {
                      final records = _recordsByDate[entry.value] ?? [];
                      final count = records
                          .where((r) => r.status == 'PRESENT')
                          .length;
                      return FlSpot(entry.key.toDouble(), count.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: dateKeys.asMap().entries.map((entry) {
                      final records = _recordsByDate[entry.value] ?? [];
                      final count = records
                          .where((r) => r.status == 'LATE')
                          .length;
                      return FlSpot(entry.key.toDouble(), count.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: dateKeys.asMap().entries.map((entry) {
                      final records = _recordsByDate[entry.value] ?? [];
                      final count = records
                          .where((r) => r.status == 'ABSENT')
                          .length;
                      return FlSpot(entry.key.toDouble(), count.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedTable() {
    if (_allRecords.isEmpty) {
      return _buildEmptyState('No attendance records found');
    }

    // Sort records by date descending
    final sortedRecords = List<AttendanceRecord>.from(_allRecords)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
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
          // Table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Check-in',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Check-out',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedRecords.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final record = sortedRecords[index];
              return _buildTableRow(record);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(AttendanceRecord record) {
    Color statusColor;
    switch (record.status) {
      case 'PRESENT':
        statusColor = Colors.green;
        break;
      case 'LATE':
        statusColor = Colors.orange;
        break;
      case 'ABSENT':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM dd, yyyy').format(record.date),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              record.checkInTime != null
                  ? DateFormat('HH:mm').format(record.checkInTime!)
                  : '--:--',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              record.checkOutTime != null
                  ? DateFormat('HH:mm').format(record.checkOutTime!)
                  : '--:--',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                record.status,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
