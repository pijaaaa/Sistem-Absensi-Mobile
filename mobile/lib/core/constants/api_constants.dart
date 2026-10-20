class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api', // Android emulator local
  );

  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);

  // Auth endpoints
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const me = '/auth/me';
  static const menus = '/auth/me/menus';
  static const permissions = '/auth/me/permissions';
  static const updateFcmToken = '/auth/fcm-token';
}
