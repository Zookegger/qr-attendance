class ApiEndpoints {
  ApiEndpoints._();

  static const String health = '/health';

  // Auth Routes
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';
  static const String resetPassword = '/auth/reset-password';

  // Attendance Routes
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String history = '/attendance/history';
  static const String createRequest = '/requests';

  // User routes
  static String userProfile(int id) => '/users/$id/profile';
}
