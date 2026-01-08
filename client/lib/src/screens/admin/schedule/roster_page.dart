import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // Import this package
import 'package:qr_attendance_frontend/src/models/schedule.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';
import 'package:qr_attendance_frontend/src/screens/admin/schedule/manage_schedule_page.dart';
import 'package:qr_attendance_frontend/src/services/admin.service.dart';
import 'package:qr_attendance_frontend/src/services/schedule.service.dart';

class RosterPage extends StatefulWidget {
  const RosterPage({super.key});

  @override
  State<RosterPage> createState() => _RosterPageState();
}

class _RosterPageState extends State<RosterPage> {
  // Calendar State
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Data State
  bool _isLoading = false;
  List<User> _users = [];
  List<Schedule> _schedules = [];

  // Map<UserId, Map<DateString, Schedule>>
  Map<String, Map<String, Schedule>> _rosterMap = {};

  // Cache to store total shift counts per day for calendar markers
  Map<String, int> _dailyShiftCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchDataForMonth(_focusedDay);
  }

  /// Fetches data for the entire visible month (plus a small buffer)
  Future<void> _fetchDataForMonth(DateTime date) async {
    setState(() => _isLoading = true);

    // Calculate start (1st of month) and end (last of month)
    // We add a buffer of 7 days before/after to handle week overlaps
    final firstDay = DateTime(
      date.year,
      date.month,
      1,
    ).subtract(const Duration(days: 7));
    final lastDay = DateTime(
      date.year,
      date.month + 1,
      0,
    ).add(const Duration(days: 7));

    try {
      final usersFuture = AdminService().getUsers();
      final schedulesFuture = ScheduleService().searchSchedules(
        from: firstDay,
        to: lastDay,
      );

      final results = await Future.wait([usersFuture, schedulesFuture]);
      _users = results[0] as List<User>;
      _schedules = results[1] as List<Schedule>;

      _processRoster(firstDay, lastDay);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading schedules: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Processes raw schedules into a lookup map for the UI
  void _processRoster(DateTime startRange, DateTime endRange) {
    _rosterMap = {};
    _dailyShiftCounts = {};

    // Initialize map for all users
    for (var user in _users) {
      _rosterMap[user.id] = {};
    }

    // Iterate through all days in the fetched range
    int daysDiff = endRange.difference(startRange).inDays;

    for (int i = 0; i <= daysDiff; i++) {
      DateTime currentDay = startRange.add(Duration(days: i));
      String dayStr = DateFormat('yyyy-MM-dd').format(currentDay);
      int shiftCount = 0;

      for (var schedule in _schedules) {
        DateTime start = schedule.startDate;
        DateTime? end = schedule.endDate;

        // 1. Check Date Range
        bool dateCovered =
            !currentDay.isBefore(start) &&
            (end == null || !currentDay.isAfter(end));

        if (dateCovered) {
          // 2. Check Day of Week (0=Sun, ... 6=Sat match)
          // Dart DateTime.weekday is 1=Mon...7=Sun.
          // We convert 7(Sun) to 0 to match standard cron/JS format if your backend uses 0-6
          int dayIndex = currentDay.weekday == 7 ? 0 : currentDay.weekday;

          bool dayIncluded =
              schedule.shift != null &&
              schedule.shift!.workDays.contains(dayIndex);

          if (dayIncluded) {
            // Add to User Map
            if (_rosterMap.containsKey(schedule.userId)) {
              _rosterMap[schedule.userId]![dayStr] = schedule;
              shiftCount++;
            }
          }
        }
      }
      // Store count for calendar markers
      if (shiftCount > 0) {
        _dailyShiftCounts[dayStr] = shiftCount;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        title: const Text(
          'Schedule Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildEmployeeList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,

        // Interaction
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() => _calendarFormat = format);
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          // Fetch new data when swiping months
          _fetchDataForMonth(focusedDay);
        },

        // Markers (Dots)
        eventLoader: (day) {
          final dayStr = DateFormat('yyyy-MM-dd').format(day);
          final count = _dailyShiftCounts[dayStr] ?? 0;
          // Return a dummy list of length 'count' to generate dots
          return List.generate(count > 3 ? 3 : count, (index) => 'Shift');
        },

        // Styling
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF4A00E0), // Brand color
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF4A00E0).withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.green, // Dot color
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    final dayStr = DateFormat('yyyy-MM-dd').format(_selectedDay);

    // Sort: People working come first
    final sortedUsers = List<User>.from(_users);
    sortedUsers.sort((a, b) {
      final hasShiftA = _rosterMap[a.id]?[dayStr] != null ? 1 : 0;
      final hasShiftB = _rosterMap[b.id]?[dayStr] != null ? 1 : 0;
      return hasShiftB.compareTo(hasShiftA); // Descending (1 before 0)
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(_selectedDay),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_dailyShiftCounts[dayStr] ?? 0} Shifts",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sortedUsers.length,
            itemBuilder: (context, index) {
              final user = sortedUsers[index];
              final schedule = _rosterMap[user.id]?[dayStr];
              final isWorking = schedule != null;

              return Card(
                elevation: isWorking ? 2 : 0,
                color: isWorking ? Colors.white : Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isWorking
                      ? BorderSide.none
                      : BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isWorking
                        ? Colors.blue.shade100
                        : Colors.grey.shade200,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0] : '?',
                      style: TextStyle(
                        color: isWorking ? Colors.blue.shade800 : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: isWorking
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isWorking ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  subtitle: isWorking
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            // Aligns the icon to the top-left of the text block
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(
                                width: 8,
                              ), 
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Top Text (Name)
                                    Text(
                                      schedule.shift?.name ?? "",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight
                                            .w600, // Made slightly bolder for hierarchy
                                        fontSize: 13,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 2,
                                    ), 
                                    Text(
                                      "(${schedule.shift?.startTime} - ${schedule.shift?.endTime})",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w400, 
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Text(
                          "No Shift Assigned",
                          style: TextStyle(fontSize: 12),
                        ),
                  trailing: IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ManageEmployeeSchedulePage(user: user),
                        ),
                      );
                      // Refresh data when coming back
                      _fetchDataForMonth(_focusedDay);
                    },
                    icon: Icon(
                      Icons.edit_calendar_outlined,
                      color: isWorking ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
