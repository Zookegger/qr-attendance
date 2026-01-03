import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_attendance_frontend/src/models/schedule.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';
import 'package:qr_attendance_frontend/src/services/admin.service.dart';
import 'package:qr_attendance_frontend/src/services/schedule.service.dart';

class RosterPage extends StatefulWidget {
  const RosterPage({super.key});

  @override
  State<RosterPage> createState() => _RosterPageState();
}

class _RosterPageState extends State<RosterPage> {
  DateTime _currentWeekStart = DateTime.now();
  bool _isLoading = false;
  List<User> _users = [];
  List<Schedule> _schedules = [];
  
  // Map<UserId, Map<DateString, Schedule>>
  Map<String, Map<String, Schedule>> _rosterMap = {};

  @override
  void initState() {
    super.initState();
    // Align to Monday
    _currentWeekStart = _currentWeekStart.subtract(Duration(days: _currentWeekStart.weekday - 1));
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final weekEnd = _currentWeekStart.add(const Duration(days: 6));
      
      final usersFuture = AdminService().getUsers();
      final schedulesFuture = ScheduleService().searchSchedules(
        from: _currentWeekStart,
        to: weekEnd,
      );

      final results = await Future.wait([usersFuture, schedulesFuture]);
      _users = results[0] as List<User>;
      _schedules = results[1] as List<Schedule>;

      _processRoster();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading roster: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processRoster() {
    _rosterMap = {};
    for (var user in _users) {
      _rosterMap[user.id] = {};
    }

    for (var schedule in _schedules) {
      // Expand schedule range to individual days
      DateTime start = schedule.startDate;
      DateTime? end = schedule.endDate;
      
      // We only care about the current week window
      
      for (int i = 0; i < 7; i++) {
        DateTime day = _currentWeekStart.add(Duration(days: i));
        String dayStr = DateFormat('yyyy-MM-dd').format(day);
        
        // Check if schedule covers this day
        bool covers = !day.isBefore(start) && (end == null || !day.isAfter(end));
        
        if (covers) {
          if (_rosterMap.containsKey(schedule.userId)) {
             _rosterMap[schedule.userId]![dayStr] = schedule;
          }
        }
      }
    }
  }

  void _changeWeek(int offset) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: offset * 7));
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeWeek(-1),
          ),
          Center(
            child: Text(
              "${DateFormat('MMM d').format(_currentWeekStart)} - ${DateFormat('MMM d').format(_currentWeekStart.add(const Duration(days: 6)))}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeWeek(1),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : OrientationBuilder(
              builder: (context, orientation) {
                return orientation == Orientation.portrait
                    ? _buildPortraitView()
                    : _buildLandscapeView();
              },
            ),
    );
  }

  Widget _buildPortraitView() {
    final days = List.generate(7, (index) => _currentWeekStart.add(Duration(days: index)));
    
    return DefaultTabController(
      length: 7,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: days.map((date) => Tab(
              text: DateFormat('E d').format(date),
            )).toList(),
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: days.map((date) => _buildDayList(date)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayList(DateTime date) {
    final dayStr = DateFormat('yyyy-MM-dd').format(date);
    
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final schedule = _rosterMap[user.id]?[dayStr];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
            ),
            title: Text(user.name),
            subtitle: schedule != null
                ? Text(
                    "${schedule.shift?.name ?? 'Shift'} (${schedule.shift?.startTime ?? ''} - ${schedule.shift?.endTime ?? ''})",
                    style: const TextStyle(color: Colors.green),
                  )
                : const Text(
                    "Off Duty",
                    style: TextStyle(color: Colors.red),
                  ),
            trailing: schedule != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
          ),
        );
      },
    );
  }

  Widget _buildLandscapeView() {
    final days = List.generate(7, (index) => _currentWeekStart.add(Duration(days: index)));
    
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                const SizedBox(width: 150, child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Employee", style: TextStyle(fontWeight: FontWeight.bold)),
                )),
                ...days.map((date) => SizedBox(
                  width: 100,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      DateFormat('E d').format(date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
              ],
            ),
            const Divider(),
            // User Rows
            ..._users.map((user) {
              return Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  ...days.map((date) {
                    final dayStr = DateFormat('yyyy-MM-dd').format(date);
                    final schedule = _rosterMap[user.id]?[dayStr];
                    
                    return Container(
                      width: 100,
                      height: 50,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: schedule != null ? Colors.blue.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: schedule == null ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
                      ),
                      child: Center(
                        child: schedule != null
                            ? Text(
                                schedule.shift?.name ?? 'Shift',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              )
                            : const Text(
                                "OFF",
                                style: TextStyle(fontSize: 10, color: Colors.red),
                              ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
