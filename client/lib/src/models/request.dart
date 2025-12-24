class Request {
  final String? id;
  final String userId;
  final String type;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? reason;
  final String? imageUrl;
  final String status;

  Request({
    this.id,
    required this.userId,
    required this.type,
    this.fromDate,
    this.toDate,
    this.reason,
    this.imageUrl,
    this.status = 'pending',
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      fromDate: json['from_date'] != null
          ? DateTime.parse(json['from_date'])
          : null,
      toDate: json['to_date'] != null ? DateTime.parse(json['to_date']) : null,
      reason: json['reason'],
      imageUrl: json['image_url'],
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'from_date': fromDate?.toIso8601String(),
      'to_date': toDate?.toIso8601String(),
      'reason': reason,
      'image_url': imageUrl,
      'status': status,
    };
  }
}
