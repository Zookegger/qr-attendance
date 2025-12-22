import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/attendance_record.dart';
import '../../services/attendance.service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final AttendanceService _service = AttendanceService();
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<DateTime, AttendanceRecord> _byDate = {};
  DateTime _selectedDay = DateTime.now();
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
      final records = await _service.fetchHistory(month: _focusedMonth);
      if (!mounted) return;
      _byDate = {
        for (final r in records)
          DateTime(r.date.year, r.date.month, r.date.day): r,
      };
      _selectedDay = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay.day.clamp(1, 28));
    } catch (e) {
      if (!mounted) return;
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    });
    _load();
  }

  Color _colorForStatus(String status) {
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

  @override
  Widget build(BuildContext context) {
    final monthLabel = '${_focusedMonth.month.toString().padLeft(2, '0')}/${_focusedMonth.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('Work schedule')),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLegend(),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (!_loading)
              TableCalendar<AttendanceRecord>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedMonth,
                currentDay: _selectedDay,
                calendarFormat: CalendarFormat.month,
                headerVisible: false,
                startingDayOfWeek: StartingDayOfWeek.monday,
                eventLoader: (day) {
                  final normalized = DateTime(day.year, day.month, day.day);
                  final record = _byDate[normalized];
                  return record == null ? [] : [record];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedMonth = focusedDay;
                  });
                },
                onPageChanged: (focused) {
                  _focusedMonth = focused;
                  _load();
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blueGrey.shade100,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final record = events.first;
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _colorForStatus(record.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    final record = _byDate[DateTime(day.year, day.month, day.day)];
                    final textColor = record == null ? Colors.black : _colorForStatus(record.status);
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            _buildSelectedDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        item(Colors.green, 'On time'),
        item(Colors.orange, 'Late'),
        item(Colors.red, 'Absent'),
        item(Colors.grey, 'Not recorded'),
      ],
    );
  }

  Widget _buildSelectedDetails() {
    final normalized = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final record = _byDate[normalized];
    if (record == null) {
      return const Text('No attendance recorded for this day.', textAlign: TextAlign.center);
    }

    final color = _colorForStatus(record.status);
    final checkIn = record.checkInTime == null ? '--:--' : _fmtTime(record.checkInTime!);
    final checkOut = record.checkOutTime == null ? '--:--' : _fmtTime(record.checkOutTime!);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(record.status, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Check-in: $checkIn'),
            Text('Check-out: $checkOut'),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
