import 'workshift.dart';
import 'user.dart'; 

class Schedule {
  final int id;
  final String userId;
  final int shiftId;
  final DateTime startDate;
  final DateTime? endDate;
  final Workshift? shift;
  final User? user;

  Schedule({
    required this.id,
    required this.userId,
    required this.shiftId,
    required this.startDate,
    this.endDate,
    this.shift,
    this.user,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      userId: json['user_id'],
      shiftId: json['shift_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      shift: json['Shift'] != null ? Workshift.fromJson(json['Shift']) : null,
      user: json['User'] != null ? User.fromJson(json['User']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'shift_id': shiftId,
      'start_date': startDate.toIso8601String().substring(0, 10), // YYYY-MM-DD
      'end_date': endDate?.toIso8601String().substring(0, 10),
    };
  }
}
