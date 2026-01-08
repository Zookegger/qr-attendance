import 'package:flutter/material.dart';

import '../../../models/attendance_record.dart';
import '../../../services/attendance.service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final AttendanceService _service = AttendanceService();
  final List<AttendanceRecord> _records = [];

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchHistory(month: _selectedMonth);
      if (!mounted) return;
      _records
        ..clear()
        ..addAll(data);
    } catch (e) {
      if (!mounted) return;
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _changeMonth(int delta) {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    setState(() => _selectedMonth = next);
    _load();
  }

  Map<String, int> _buildStats() {
    final stats = <String, int>{'Present': 0, 'Late': 0, 'Absent': 0};
    for (final r in _records) {
      if (stats.containsKey(r.status)) {
        stats[r.status] = stats[r.status]! + 1;
      }
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _buildStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          // style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // backgroundColor: const Color(0xFF4A00E0),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            _buildMonthHeader(),
            if (!_loading && _records.isNotEmpty) _buildQuickStats(stats),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
            if (!_loading && _records.isEmpty && _error == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No attendance records for ${_getMonthLabel()}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            if (!_loading && _records.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Records',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._records.map(_buildRecordTile),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF5F7FA),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            _getMonthLabel(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, int> stats) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatBubble('Present', stats['Present'] ?? 0, Colors.green),
          const SizedBox(width: 12),
          _buildStatBubble('Late', stats['Late'] ?? 0, Colors.orange),
          const SizedBox(width: 12),
          _buildStatBubble('Absent', stats['Absent'] ?? 0, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordTile(AttendanceRecord record) {
    final dateLabel = _formatDate(record.date);
    final checkIn = _formatTime(record.checkInTime);
    final checkOut = _formatTime(record.checkOutTime);

    final statusColor = _getStatusColor(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 4,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          dateLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Expanded(child: Text('In: $checkIn')),
            Expanded(child: Text('Out: $checkOut')),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            record.status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Late':
        return Colors.orange;
      case 'Absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getMonthLabel() {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  String _formatDate(DateTime date) {
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdayNames[date.weekday - 1];
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ($weekday)';
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '--:--';
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
