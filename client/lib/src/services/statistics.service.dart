import 'package:dio/dio.dart';
import '../consts/api_endpoints.dart';
import '../utils/api_client.dart';

class PersonalStats {
  final String? checkInTime;
  final String? checkOutTime;
  final String totalTime;
  final bool isCheckedIn;
  final int daysWorked;
  final int daysOff;
  final String overtimeHours;
  final int lateArrivals;

  PersonalStats({
    this.checkInTime,
    this.checkOutTime,
    required this.totalTime,
    required this.isCheckedIn,
    required this.daysWorked,
    required this.daysOff,
    required this.overtimeHours,
    required this.lateArrivals,
  });

  factory PersonalStats.fromJson(Map<String, dynamic> json) {
    return PersonalStats(
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      totalTime: json['totalTime'] ?? '--:--',
      isCheckedIn: json['isCheckedIn'] ?? false,
      daysWorked: json['daysWorked'] ?? 0,
      daysOff: json['daysOff'] ?? 0,
      overtimeHours: json['overtimeHours'] ?? '0h',
      lateArrivals: json['lateArrivals'] ?? 0,
    );
  }
}

class TodayShift {
  final String? checkInTime;
  final String? checkOutTime;
  final String totalTime;
  final bool isCheckedIn;
  final String? status;

  TodayShift({
    this.checkInTime,
    this.checkOutTime,
    required this.totalTime,
    required this.isCheckedIn,
    this.status,
  });

  factory TodayShift.fromJson(Map<String, dynamic> json) {
    return TodayShift(
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      totalTime: json['totalTime'] ?? '--:--',
      isCheckedIn: json['isCheckedIn'] ?? false,
      status: json['status'],
    );
  }
}

class TeamStats {
  final int teamPresent;
  final int teamLate;
  final int teamAbsent;
  final int total;

  TeamStats({
    required this.teamPresent,
    required this.teamLate,
    required this.teamAbsent,
    required this.total,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) {
    return TeamStats(
      teamPresent: json['teamPresent'] ?? 0,
      teamLate: json['teamLate'] ?? 0,
      teamAbsent: json['teamAbsent'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class TeamAttendanceDetail {
  final String userId;
  final String userName;
  final String? userEmail;
  final String? position;
  final String? department;
  final String? checkInTime;
  final String? checkOutTime;
  final String status;
  final bool isCheckedIn;

  TeamAttendanceDetail({
    required this.userId,
    required this.userName,
    this.userEmail,
    this.position,
    this.department,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    required this.isCheckedIn,
  });

  factory TeamAttendanceDetail.fromJson(Map<String, dynamic> json) {
    return TeamAttendanceDetail(
      userId: json['userId'],
      userName: json['userName'] ?? 'Unknown',
      userEmail: json['userEmail'],
      position: json['position'],
      department: json['department'],
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      status: json['status'] ?? 'ABSENT',
      isCheckedIn: json['isCheckedIn'] ?? false,
    );
  }
}

class StatisticsService {
  StatisticsService({Dio? dio})
      : _dio = dio ?? ApiClient().client;

  final Dio _dio;

  /// Get personal statistics for a user
  Future<PersonalStats> getPersonalStats(
    String userId, {
    int? month,
    int? year,
  }) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;

    final response = await _dio.get(
      '${ApiEndpoints.statistics}/personal/$userId',
      queryParameters: queryParams,
    );

    if (response.data['success'] == true) {
      return PersonalStats.fromJson(response.data['data']);
    }

    throw Exception('Failed to fetch personal statistics');
  }

  /// Get today's shift status for a user
  Future<TodayShift> getTodayShift(String userId) async {
    final response = await _dio.get(
      '${ApiEndpoints.statistics}/today/$userId',
    );

    if (response.data['success'] == true) {
      return TodayShift.fromJson(response.data['data']);
    }

    throw Exception('Failed to fetch today\'s shift');
  }

  /// Get team statistics (managers/admins only)
  Future<TeamStats> getTeamStats() async {
    final response = await _dio.get(
      '${ApiEndpoints.statistics}/team',
    );

    if (response.data['success'] == true) {
      return TeamStats.fromJson(response.data['data']);
    }

    throw Exception('Failed to fetch team statistics');
  }

  /// Get detailed team attendance (managers/admins only)
  Future<List<TeamAttendanceDetail>> getTeamAttendanceDetails() async {
    final response = await _dio.get(
      '${ApiEndpoints.statistics}/team/details',
    );

    if (response.data['success'] == true) {
      final data = response.data['data'] as List;
      return data
          .map((json) => TeamAttendanceDetail.fromJson(json))
          .toList();
    }

    throw Exception('Failed to fetch team attendance details');
  }
}
