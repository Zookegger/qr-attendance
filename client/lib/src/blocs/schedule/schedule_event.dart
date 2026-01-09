import 'package:equatable/equatable.dart';
import 'package:qr_attendance_frontend/src/models/schedule.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object?> get props => [];
}

class ScheduleFetchForMonth extends ScheduleEvent {
  final DateTime date;

  const ScheduleFetchForMonth({required this.date});

  @override
  List<Object?> get props => [date];
}

class ScheduleCreate extends ScheduleEvent {
  final Schedule schedule;

  const ScheduleCreate({required this.schedule});

  @override
  List<Object?> get props => [schedule];
}

class ScheduleUpdate extends ScheduleEvent {
  final Schedule schedule;

  const ScheduleUpdate({required this.schedule});

  @override
  List<Object?> get props => [schedule];
}

class ScheduleDelete extends ScheduleEvent {
  final String scheduleId;

  const ScheduleDelete({required this.scheduleId});

  @override
  List<Object?> get props => [scheduleId];
}

class ScheduleDateSelected extends ScheduleEvent {
  final DateTime selectedDate;

  const ScheduleDateSelected({required this.selectedDate});

  @override
  List<Object?> get props => [selectedDate];
}

class ScheduleCalendarFormatChanged extends ScheduleEvent {
  final String format; // 'month', 'week', 'twoWeeks'

  const ScheduleCalendarFormatChanged({required this.format});

  @override
  List<Object?> get props => [format];
}
