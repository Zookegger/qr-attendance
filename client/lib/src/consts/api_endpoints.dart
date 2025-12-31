class ApiEndpoints {
  ApiEndpoints._();

  static const String health = '/health';

  // Auth Routes
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String unbindDevice = '/admin/unbind-device';

  // Attendance Routes
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String history = '/attendance/history';
  static const String createRequest = '/requests';

  // Admin Routes
  static const String adminQr = '/admin/qr';
  static const String adminConfig = '/admin/config';
  static const String adminReport = '/admin/report';
  static const String adminUsers = '/admin/users';
  static String adminUser(String id) => '/admin/users/$id';
  static String adminUserSessions(String id) => '/admin/users/$id/sessions';
  static String revokeSession(String id) => '/admin/sessions/$id';

  // User routes
  static String userProfile(String id) => '/users/$id/profile';

  // Schedule routes
  static const String schedules = '/schedules';
  static const String schedulesSearch = '/schedules/search';
  static String scheduleById(int id) => '/schedules/$id';

  // Workshift routes
  static const String workshifts = '/workshifts';
  static String workshiftById(int id) => '/workshifts/$id';
}
