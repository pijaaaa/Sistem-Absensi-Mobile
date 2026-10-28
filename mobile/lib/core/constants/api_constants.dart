class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.137.1:8000/api',
  );

  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);

  // Auth endpoints
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const me = '/me';
  static const menus = '/me/menus';
  static const permissions = '/me/permissions';
  static const updateFcmToken = '/auth/fcm-token';

  // Face endpoints
  static const faceEnroll = '/face/enroll';
  static const faceVerify = '/face/verify';
  static const faceTemplate = '/face/template';
  static const faceDelete = '/face/template';
  static const fcmToken = '/push-tokens';
  static String pushTokenDelete(String token) => '/push-tokens/$token';

  static const notificationPreferences = '/me/notification-preferences';

  // Security endpoints
  static const securityReport = '/security/report';
}
