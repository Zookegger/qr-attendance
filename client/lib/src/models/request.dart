import 'dart:convert';

class Request {
  final String? id;
  final String userId;
  final String type;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? reason;
  final List<String>? attachments;
  final String status;
  final String? reviewedBy;
  final String? reviewNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Request({
    this.id,
    required this.userId,
    required this.type,
    this.fromDate,
    this.toDate,
    this.reason,
    this.attachments,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewNote,
    this.createdAt,
    this.updatedAt,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v as String);
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
      userId: json['user_id'],
      type: json['type'],
      fromDate: json['from_date'] != null
          ? DateTime.parse(json['from_date'])
          : null,
      toDate: json['to_date'] != null ? DateTime.parse(json['to_date']) : null,
      reason: json['reason'],
      attachments: parseAttachments(json['attachments'] ?? json['attachments']),
      status: json['status'] ?? 'pending',
      reviewedBy: json['reviewed_by'] ?? json['reviewedBy'],
      reviewNote: json['review_note'] ?? json['reviewNote'],
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'from_date': fromDate?.toIso8601String(),
      'to_date': toDate?.toIso8601String(),
      'reason': reason,
      'attachments': attachments != null ? jsonEncode(attachments) : null,
      'reviewed_by': reviewedBy,
      'review_note': reviewNote,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
