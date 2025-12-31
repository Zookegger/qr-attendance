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
      checkInTime: parseDate(json['check_in_time'] ?? json['checkInTime']),
      checkOutTime: parseDate(json['check_out_time'] ?? json['checkOutTime']),
      checkInMethod: json['check_in_method'] as String?,
      checkOutMethod: json['check_out_method'] as String?,
      scheduleId: json['schedule_id'] is int
          ? json['schedule_id'] as int
          : (json['scheduleId'] is int ? json['scheduleId'] as int : null),
      requestId: json['request_id'] ?? json['requestId'],
      checkInLocation: json['check_in_location'] as Map<String, dynamic>?,
      checkOutLocation: json['check_out_location'] as Map<String, dynamic>?,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
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
