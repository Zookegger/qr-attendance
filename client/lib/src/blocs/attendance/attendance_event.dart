import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class AttendanceCheckIn extends AttendanceEvent {
  final String qrCode;
  final double latitude;
  final double longitude;

  const AttendanceCheckIn({
    required this.qrCode,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [qrCode, latitude, longitude];
}

class AttendanceCheckOut extends AttendanceEvent {
  final String qrCode;
  final double latitude;
  final double longitude;

  const AttendanceCheckOut({
    required this.qrCode,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [qrCode, latitude, longitude];
}

class AttendanceFetchHistory extends AttendanceEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? userId;

  const AttendanceFetchHistory({
    this.startDate,
    this.endDate,
    this.userId,
  });

  @override
  List<Object?> get props => [startDate, endDate, userId];
}

class AttendanceFetchTodayStatus extends AttendanceEvent {
  const AttendanceFetchTodayStatus();
}
