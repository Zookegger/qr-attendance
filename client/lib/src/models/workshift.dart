import 'dart:convert';

class Workshift {
  final int id;
  final String name;
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String breakStart;
  final String breakEnd;
  final int gracePeriod;
  final List<int> workDays; // [0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat]
  final int? officeConfigId;

  Workshift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.breakStart,
    required this.breakEnd,
    required this.gracePeriod,
    required this.workDays,
    this.officeConfigId,
  });

  factory Workshift.fromJson(Map<String, dynamic> json) {
    return Workshift(
      id: json['id'],
      name: json['name'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      breakStart: json['breakStart'],
      breakEnd: json['breakEnd'],
      gracePeriod: json['gracePeriod'] ?? 15,
      workDays: _parseWorkDays(json['workDays']),
      officeConfigId: json['officeConfigId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'breakStart': breakStart,
      'breakEnd': breakEnd,
      'gracePeriod': gracePeriod,
      'workDays': workDays,
      'officeConfigId': officeConfigId,
    };
  }

  static String formatDays(List<int> days) {
    // 0=Sun, 1=Mon, ..., 6=Sat
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (days.length == 7) return 'Every day';
    if (days.isEmpty) return 'No days assigned';
    days.sort();
    return days.map((d) => names[d % 7]).join(', ');
  }

  static List<int> _parseWorkDays(dynamic value) {
    if (value is List) {
      return List<int>.from(value).toSet().toList()..sort();
    } else if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return List<int>.from(decoded).toSet().toList()..sort();
        }
      } catch (_) {}
      // Fallback to split
      return value
          .split(',')
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .toList()
          .toSet()
          .toList()
        ..sort();
    }
    return [];
  }
}
