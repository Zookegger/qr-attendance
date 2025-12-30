class AttendanceRecord {
  final int id;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final String? checkInMethod;
  final String? checkOutMethod;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.checkInMethod,
    this.checkOutMethod,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value as String);
      } catch (_) {
        return null;
      }
    }

    final rawId = json['id'];
    final rawDate = json['date'];
    return AttendanceRecord(
      id: rawId is int ? rawId : (int.tryParse(rawId.toString()) ?? 0),
      date: rawDate != null
          ? DateTime.parse(rawDate as String)
          : DateTime.now(),
      status: (json['status'] as String?) ?? 'Unknown',
      checkInTime: parseDate(json['check_in_time']),
      checkOutTime: parseDate(json['check_out_time']),
      checkInMethod: json['check_in_method'] as String?,
      checkOutMethod: json['check_out_method'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    String? formatDate(DateTime? dt) => dt?.toIso8601String();

    return {
      'id': id,
      'date': date.toIso8601String(),
      'check_in_time': formatDate(checkInTime),
      'check_out_time': formatDate(checkOutTime),
      'status': status,
      'check_in_method': checkInMethod,
      'check_out_method': checkOutMethod,
    };
  }
}
