import 'package:equatable/equatable.dart';

import 'package:qr_attendance_frontend/src/models/schedule.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => [];
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class ScheduleLoaded extends ScheduleState {
  final List<User> users;
  final List<Schedule> schedules;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final String calendarFormat; // 'month', 'week', 'twoWeeks'
  final Map<String, Map<String, Schedule>> rosterMap;
  final Map<String, int> dailyShiftCounts;

  const ScheduleLoaded({
    required this.users,
    required this.schedules,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.rosterMap,
    required this.dailyShiftCounts,
  });

  @override
  List<Object?> get props => [
        users,
        schedules,
        focusedDay,
        selectedDay,
        calendarFormat,
        rosterMap,
        dailyShiftCounts,
      ];

  ScheduleLoaded copyWith({
    List<User>? users,
    List<Schedule>? schedules,
    DateTime? focusedDay,
    DateTime? selectedDay,
    String? calendarFormat,
    Map<String, Map<String, Schedule>>? rosterMap,
    Map<String, int>? dailyShiftCounts,
  }) {
    return ScheduleLoaded(
      users: users ?? this.users,
      schedules: schedules ?? this.schedules,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      rosterMap: rosterMap ?? this.rosterMap,
      dailyShiftCounts: dailyShiftCounts ?? this.dailyShiftCounts,
    );
  }
}

class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ScheduleOperationSuccess extends ScheduleState {
  final String message;

  const ScheduleOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
