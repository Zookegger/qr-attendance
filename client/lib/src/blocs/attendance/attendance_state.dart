import 'package:equatable/equatable.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

class AttendanceCheckInSuccess extends AttendanceState {
  final String message;
  final DateTime timestamp;

  const AttendanceCheckInSuccess({
    required this.message,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [message, timestamp];
}

class AttendanceCheckOutSuccess extends AttendanceState {
  final String message;
  final DateTime timestamp;

  const AttendanceCheckOutSuccess({
    required this.message,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [message, timestamp];
}

class AttendanceHistoryLoaded extends AttendanceState {
  final List<dynamic> records; // List<AttendanceRecord>
  final DateTime? startDate;
  final DateTime? endDate;

  const AttendanceHistoryLoaded({
    required this.records,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [records, startDate, endDate];
}

class AttendanceTodayStatusLoaded extends AttendanceState {
  final bool hasCheckedIn;
  final bool hasCheckedOut;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  const AttendanceTodayStatusLoaded({
    required this.hasCheckedIn,
    required this.hasCheckedOut,
    this.checkInTime,
    this.checkOutTime,
  });

  @override
  List<Object?> get props => [
        hasCheckedIn,
        hasCheckedOut,
        checkInTime,
        checkOutTime,
      ];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({required this.message});

  @override
  List<Object?> get props => [message];
}
