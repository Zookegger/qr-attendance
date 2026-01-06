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
      userId: json['userId'],
      shiftId: json['shiftId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
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
