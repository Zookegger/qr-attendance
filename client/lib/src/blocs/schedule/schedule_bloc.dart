import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_attendance_frontend/src/blocs/schedule/schedule_event.dart';
import 'package:qr_attendance_frontend/src/blocs/schedule/schedule_state.dart';
import 'package:qr_attendance_frontend/src/models/schedule.dart';
import 'package:qr_attendance_frontend/src/services/admin.service.dart';
import 'package:qr_attendance_frontend/src/services/schedule.service.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleService _scheduleService;
  final AdminService _adminService;

  ScheduleBloc({
    ScheduleService? scheduleService,
    AdminService? adminService,
  })  : _scheduleService = scheduleService ?? ScheduleService(),
        _adminService = adminService ?? AdminService(),
        super(const ScheduleInitial()) {
    on<ScheduleFetchForMonth>(_onScheduleFetchForMonth);
    on<ScheduleCreate>(_onScheduleCreate);
    on<ScheduleUpdate>(_onScheduleUpdate);
    on<ScheduleDelete>(_onScheduleDelete);
    on<ScheduleDateSelected>(_onScheduleDateSelected);
    on<ScheduleCalendarFormatChanged>(_onScheduleCalendarFormatChanged);
  }

  Future<void> _onScheduleFetchForMonth(
    ScheduleFetchForMonth event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());
    try {
      final firstDay = DateTime(
        event.date.year,
        event.date.month,
        1,
      ).subtract(const Duration(days: 7));
      
      final lastDay = DateTime(
        event.date.year,
        event.date.month + 1,
        0,
      ).add(const Duration(days: 7));

      final users = await _adminService.getUsers();
      final schedules = await _scheduleService.searchSchedules(
        from: firstDay,
        to: lastDay,
      );

      final processedData = _processRoster(users, schedules, firstDay, lastDay);

      emit(ScheduleLoaded(
        users: users,
        schedules: schedules,
        focusedDay: event.date,
        selectedDay: event.date,
        calendarFormat: 'month',
        rosterMap: processedData['rosterMap'] as Map<String, Map<String, Schedule>>,
        dailyShiftCounts: processedData['dailyShiftCounts'] as Map<String, int>,
      ));
    } catch (e) {
      emit(ScheduleError(message: 'Error loading schedules: $e'));
    }
  }

  Future<void> _onScheduleCreate(
    ScheduleCreate event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is! ScheduleLoaded) return;
    
    try {
      final scheduleData = event.schedule.toJson();
      await _scheduleService.assignSchedule(scheduleData);
      emit(const ScheduleOperationSuccess(message: 'Schedule created successfully'));
      
      // Reload the data
      final currentState = state as ScheduleLoaded;
      add(ScheduleFetchForMonth(date: currentState.focusedDay));
    } catch (e) {
      emit(ScheduleError(message: 'Error creating schedule: $e'));
    }
  }

  Future<void> _onScheduleUpdate(
    ScheduleUpdate event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is! ScheduleLoaded) return;
    
    try {
      final scheduleData = event.schedule.toJson();
      await _scheduleService.assignSchedule(scheduleData);
      emit(const ScheduleOperationSuccess(message: 'Schedule updated successfully'));
      
      // Reload the data
      final currentState = state as ScheduleLoaded;
      add(ScheduleFetchForMonth(date: currentState.focusedDay));
    } catch (e) {
      emit(ScheduleError(message: 'Error updating schedule: $e'));
    }
  }

  Future<void> _onScheduleDelete(
    ScheduleDelete event,
    Emitter<ScheduleState> emit,
  ) async {
    if (state is! ScheduleLoaded) return;
    
    try {
      final scheduleId = int.tryParse(event.scheduleId);
      if (scheduleId == null) {
        throw Exception('Invalid schedule ID');
      }
      await _scheduleService.deleteSchedule(scheduleId);
      emit(const ScheduleOperationSuccess(message: 'Schedule deleted successfully'));
      
      // Reload the data
      final currentState = state as ScheduleLoaded;
      add(ScheduleFetchForMonth(date: currentState.focusedDay));
    } catch (e) {
      emit(ScheduleError(message: 'Error deleting schedule: $e'));
    }
  }

  void _onScheduleDateSelected(
    ScheduleDateSelected event,
    Emitter<ScheduleState> emit,
  ) {
    if (state is! ScheduleLoaded) return;
    
    final currentState = state as ScheduleLoaded;
    emit(currentState.copyWith(selectedDay: event.selectedDate));
  }

  void _onScheduleCalendarFormatChanged(
    ScheduleCalendarFormatChanged event,
    Emitter<ScheduleState> emit,
  ) {
    if (state is! ScheduleLoaded) return;
    
    final currentState = state as ScheduleLoaded;
    emit(currentState.copyWith(calendarFormat: event.format));
  }

  Map<String, dynamic> _processRoster(
    List users,
    List<Schedule> schedules,
    DateTime startRange,
    DateTime endRange,
  ) {
    final rosterMap = <String, Map<String, Schedule>>{};
    final dailyShiftCounts = <String, int>{};

    // Initialize map for all users
    for (var user in users) {
      rosterMap[user.id] = {};
    }

    // Iterate through all days in the fetched range
    int daysDiff = endRange.difference(startRange).inDays;

    for (int i = 0; i <= daysDiff; i++) {
      DateTime currentDay = startRange.add(Duration(days: i));
      String dayStr = DateFormat('yyyy-MM-dd').format(currentDay);
      int shiftCount = 0;

      for (var schedule in schedules) {
        DateTime start = schedule.startDate;
        DateTime? end = schedule.endDate;

        bool isRecurring = start.isBefore(currentDay) &&
            (end == null || !end.isBefore(currentDay));
        bool isSingleDay = start.year == currentDay.year &&
            start.month == currentDay.month &&
            start.day == currentDay.day;

        if (isRecurring || isSingleDay) {
          rosterMap[schedule.userId]?[dayStr] = schedule;
          shiftCount++;
        }
      }

      dailyShiftCounts[dayStr] = shiftCount;
    }

    return {
      'rosterMap': rosterMap,
      'dailyShiftCounts': dailyShiftCounts,
    };
  }
}
