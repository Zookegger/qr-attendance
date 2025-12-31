import 'package:fl_chart/fl_chart.dart';
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
    final monthLabel =
        '${_selectedMonth.month.toString().padLeft(2, '0')}/${_selectedMonth.year}';
    final stats = _buildStats();

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance history')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPie(stats),
            const SizedBox(height: 12),
            _buildStatsRow(stats),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ..._records.map(_buildTile),
            if (!_loading && _records.isEmpty && _error == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No attendance data for this month.'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPie(Map<String, int> stats) {
    final total = stats.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No data available for the chart.')),
      );
    }

    final sections = <PieChartSectionData>[];

    void addSection(String label, int value, Color color) {
      if (value == 0) return;
      sections.add(
        PieChartSectionData(
          value: value.toDouble(),
          color: color,
          title: '${((value / total) * 100).toStringAsFixed(0)}%',
          radius: 52,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    addSection('Present', stats['Present'] ?? 0, Colors.green);
    addSection('Late', stats['Late'] ?? 0, Colors.orange);
    addSection('Absent', stats['Absent'] ?? 0, Colors.red);

    return SizedBox(
      height: 220,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendDot(Colors.green, 'On time (${stats['Present']})'),
                  _legendDot(Colors.orange, 'Late (${stats['Late']})'),
                  _legendDot(Colors.red, 'Absent (${stats['Absent']})'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, int> stats) {
    Color colorFor(String status) {
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stats.entries
          .map(
            (e) => Chip(
              backgroundColor: colorFor(e.key).withValues(alpha: 0.15),
              label: Text('${e.key}: ${e.value}'),
              labelStyle: TextStyle(color: colorFor(e.key)),
            ),
          )
          .toList(),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildTile(AttendanceRecord record) {
    final dateLabel = _formatDate(record.date);
    final checkIn = _formatTime(record.checkInTime);
    final checkOut = _formatTime(record.checkOutTime);

    Color badgeColor;
    switch (record.status) {
      case 'Present':
        badgeColor = Colors.green;
        break;
      case 'Late':
        badgeColor = Colors.orange;
        break;
      case 'Absent':
        badgeColor = Colors.red;
        break;
      default:
        badgeColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          dateLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Check-in: $checkIn'),
            Text('Check-out: $checkOut'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            record.status,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
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
