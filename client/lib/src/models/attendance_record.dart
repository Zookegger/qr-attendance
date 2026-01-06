class AttendanceRecord {
  final int id;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final String? checkInMethod;
  final String? checkOutMethod;
  final int? scheduleId;
  final String? requestId;
  final Map<String, dynamic>? checkInLocation;
  final Map<String, dynamic>? checkOutLocation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.checkInMethod,
    this.checkOutMethod,
    this.scheduleId,
    this.requestId,
    this.checkInLocation,
    this.checkOutLocation,
    this.createdAt,
    this.updatedAt,
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
      checkInTime: parseDate(json['checkInTime']),
      checkOutTime: parseDate(json['checkOutTime']),
      checkInMethod: json['checkInMethod'] as String?,
      checkOutMethod: json['checkOutMethod'] as String?,
      scheduleId: json['scheduleId'] is int ? json['scheduleId'] as int : null,
      requestId: json['requestId'],
      checkInLocation: json['checkInLocation'] as Map<String, dynamic>?,
      checkOutLocation: json['checkOutLocation'] as Map<String, dynamic>?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
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
      'schedule_id': scheduleId,
      'request_id': requestId,
      'check_in_location': checkInLocation,
      'check_out_location': checkOutLocation,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
