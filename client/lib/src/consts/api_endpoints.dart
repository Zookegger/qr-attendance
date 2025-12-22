class ApiEndpoints {
  ApiEndpoints._();

  static const String health = '/health';

  // Auth Routes
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';

  // Attendance Routes
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String history = '/attendance/history';

  // User routes
  static String userProfile(int id) => '/users/$id/profile';
}
