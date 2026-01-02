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
      startTime: json['startTime'] ?? json['start_time'],
      endTime: json['endTime'] ?? json['end_time'],
      breakStart: json['breakStart'] ?? json['break_start'],
      breakEnd: json['breakEnd'] ?? json['break_end'],
      gracePeriod: json['gracePeriod'] ?? json['grace_period'] ?? 15,
      workDays: _parseWorkDays(json['workDays'] ?? json['work_days']),
      officeConfigId: json['office_config_id'],
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
      'office_config_id': officeConfigId,
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
