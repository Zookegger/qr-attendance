import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:qr_attendance_frontend/src/blocs/schedule/schedule_bloc.dart';
import 'package:qr_attendance_frontend/src/blocs/schedule/schedule_event.dart';
import 'package:qr_attendance_frontend/src/blocs/schedule/schedule_state.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';
import 'package:qr_attendance_frontend/src/screens/admin/schedule/manage_schedule_page.dart';

class RosterPage extends StatelessWidget {
  const RosterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ScheduleBloc()..add(ScheduleFetchForMonth(date: DateTime.now())),
      child: const _RosterPageContent(),
    );
  }
}

class _RosterPageContent extends StatelessWidget {
  const _RosterPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Schedule Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: BlocConsumer<ScheduleBloc, ScheduleState>(
        listener: (context, state) {
          if (state is ScheduleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ScheduleOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ScheduleLoading || state is ScheduleInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ScheduleLoaded) {
            return Column(
              children: [
                _buildCalendar(context, state),
                const Divider(height: 1),
                Expanded(child: _buildEmployeeList(context, state)),
              ],
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, ScheduleLoaded state) {
    final calendarFormat = state.calendarFormat == 'month'
        ? CalendarFormat.month
        : state.calendarFormat == 'week'
            ? CalendarFormat.week
            : CalendarFormat.twoWeeks;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: state.focusedDay,
        calendarFormat: calendarFormat,
        selectedDayPredicate: (day) => isSameDay(state.selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(state.selectedDay, selectedDay)) {
            context
                .read<ScheduleBloc>()
                .add(ScheduleDateSelected(selectedDate: selectedDay));
          }
        },
        onFormatChanged: (format) {
          final formatString = format == CalendarFormat.month
              ? 'month'
              : format == CalendarFormat.week
                  ? 'week'
                  : 'twoWeeks';
          context
              .read<ScheduleBloc>()
              .add(ScheduleCalendarFormatChanged(format: formatString));
        },
        onPageChanged: (focusedDay) {
          context
              .read<ScheduleBloc>()
              .add(ScheduleFetchForMonth(date: focusedDay));
        },
        eventLoader: (day) {
          final dayStr = DateFormat('yyyy-MM-dd').format(day);
          final count = state.dailyShiftCounts[dayStr] ?? 0;
          return List.generate(count > 3 ? 3 : count, (index) => 'Shift');
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF4A00E0),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF4A00E0).withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList(BuildContext context, ScheduleLoaded state) {
    final dayStr = DateFormat('yyyy-MM-dd').format(state.selectedDay);

    final sortedUsers = List<User>.from(state.users);
    sortedUsers.sort((a, b) {
      final hasShiftA = state.rosterMap[a.id]?[dayStr] != null ? 1 : 0;
      final hasShiftB = state.rosterMap[b.id]?[dayStr] != null ? 1 : 0;
      return hasShiftB.compareTo(hasShiftA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(state.selectedDay),
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
                  "${state.dailyShiftCounts[dayStr] ?? 0} Shifts",
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
              final schedule = state.rosterMap[user.id]?[dayStr];
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
                      fontWeight:
                          isWorking ? FontWeight.bold : FontWeight.normal,
                      color: isWorking ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  subtitle: isWorking
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      schedule.shift?.name ?? "",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
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
                      if (context.mounted) {
                        context.read<ScheduleBloc>().add(
                              ScheduleFetchForMonth(date: state.focusedDay),
                            );
                      }
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
