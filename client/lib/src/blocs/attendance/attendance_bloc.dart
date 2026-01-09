import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_attendance_frontend/src/blocs/attendance/attendance_event.dart';
import 'package:qr_attendance_frontend/src/blocs/attendance/attendance_state.dart';
import 'package:qr_attendance_frontend/src/services/attendance.service.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceService _attendanceService;

  AttendanceBloc({
    AttendanceService? attendanceService,
  })  : _attendanceService = attendanceService ?? AttendanceService(),
        super(const AttendanceInitial()) {
    on<AttendanceCheckIn>(_onAttendanceCheckIn);
    on<AttendanceCheckOut>(_onAttendanceCheckOut);
    on<AttendanceFetchHistory>(_onAttendanceFetchHistory);
    on<AttendanceFetchTodayStatus>(_onAttendanceFetchTodayStatus);
  }

  Future<void> _onAttendanceCheckIn(
    AttendanceCheckIn event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    try {
      await _attendanceService.checkIn(
        code: event.qrCode,
        latitude: event.latitude,
        longitude: event.longitude,
      );
      
      emit(AttendanceCheckInSuccess(
        message: 'Check-in successful',
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      emit(AttendanceError(message: 'Check-in failed: $e'));
    }
  }

  Future<void> _onAttendanceCheckOut(
    AttendanceCheckOut event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    try {
      await _attendanceService.checkOut(
        code: event.qrCode,
        latitude: event.latitude,
        longitude: event.longitude,
      );
      
      emit(AttendanceCheckOutSuccess(
        message: 'Check-out successful',
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      emit(AttendanceError(message: 'Check-out failed: $e'));
    }
  }

  Future<void> _onAttendanceFetchHistory(
    AttendanceFetchHistory event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    try {
      final month = event.startDate ?? DateTime.now();
      final records = await _attendanceService.fetchHistory(month: month);
      
      emit(AttendanceHistoryLoaded(
        records: records,
        startDate: event.startDate,
        endDate: event.endDate,
      ));
    } catch (e) {
      emit(AttendanceError(message: 'Failed to load history: $e'));
    }
  }

  Future<void> _onAttendanceFetchTodayStatus(
    AttendanceFetchTodayStatus event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    try {
      // Fetch today's records and determine status
      final today = DateTime.now();
      final records = await _attendanceService.fetchHistory(month: today);
      
      final todayRecords = records.where((record) {
        final recordDate = record.checkInTime;
        if (recordDate == null) return false;
        return recordDate.year == today.year &&
            recordDate.month == today.month &&
            recordDate.day == today.day;
      }).toList();
      
      final hasCheckedIn = todayRecords.isNotEmpty;
      final hasCheckedOut = todayRecords.any((r) => r.checkOutTime != null);
      final checkInTime = hasCheckedIn ? todayRecords.first.checkInTime : null;
      final checkOutTime = hasCheckedOut ? todayRecords.first.checkOutTime : null;
      
      emit(AttendanceTodayStatusLoaded(
        hasCheckedIn: hasCheckedIn,
        hasCheckedOut: hasCheckedOut,
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
      ));
    } catch (e) {
      emit(AttendanceError(message: 'Failed to load today\'s status: $e'));
    }
  }
}
