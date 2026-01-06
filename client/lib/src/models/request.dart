import 'dart:convert';

enum RequestType {
  LEAVE,
  SICK,
  UNPAID,
  LATE_EARLY,
  OVERTIME,
  BUSINESS_TRIP,
  SHIFT_CHANGE,
  REMOTE_WORK,
  ATTENDANCE_CONFIRMATION,
  ATTENDANCE_ADJUSTMENT,
  EXPLANATION,
  OTHER;

  static RequestType fromString(String? value) {
    if (value == null || value.isEmpty) return RequestType.OTHER;
    final v = value.toUpperCase();
    return RequestType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => RequestType.OTHER,
    );
  }

  String toTextString() {
    final s = name.replaceAll('_', ' ').toLowerCase();
    return s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '';
  }
}

enum RequestStatus {
  PENDING,
  APPROVED,
  REJECTED;

  static RequestStatus fromString(String? value) {
    if (value == null || value.isEmpty) return RequestStatus.PENDING;
    final v = value.toUpperCase();
    return RequestStatus.values.firstWhere(
      (e) => e.name == v,
      orElse: () => RequestStatus.PENDING,
    );
  }
}

class Request {
  final String? id;
  final String userId;
  final RequestType type;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? reason;
  final List<String>? attachments;
  final RequestStatus status;
  final String? reviewedBy;
  final String? reviewNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userName;

  Request({
    this.id,
    required this.userId,
    required this.type,
    this.fromDate,
    this.toDate,
    this.reason,
    this.attachments,
    this.status = RequestStatus.PENDING,
    this.reviewedBy,
    this.reviewNote,
    this.createdAt,
    this.updatedAt,
    this.userName,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    List<String>? parseAttachments(dynamic v) {
      if (v == null) return null;
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return null;
    }

    return Request(
      id: json['id'],
      userId: json['userId'],
      type: RequestType.fromString(json['type']),
      fromDate: json['fromDate'] != null
          ? DateTime.parse(json['fromDate'])
          : null,
      toDate: json['toDate'] != null ? DateTime.parse(json['toDate']) : null,
      reason: json['reason'],
      attachments: parseAttachments(json['attachments']),
      status: RequestStatus.fromString(json['status']),
      reviewedBy: json['reviewedBy'],
      reviewNote: json['reviewNote'],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      userName: json['user'] != null ? json['user']['name'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type.name,
      'from_date': fromDate?.toIso8601String(),
      'to_date': toDate?.toIso8601String(),
      'reason': reason,
      'attachments': attachments != null ? jsonEncode(attachments) : null,
      'reviewed_by': reviewedBy,
      'review_note': reviewNote,
      'status': status.name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
