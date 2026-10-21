import 'package:flutter/services.dart';

/// Native Android method channel for security checks
class NativeSecurityService {
  static const _channel = MethodChannel('com.absensi.mobile/security');

  /// Check if mock location is enabled (requires Android native code)
  static Future<bool> isMockLocationEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isMockLocationEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Check if location mock provider is active
  static Future<bool> isLocationMocked() async {
    try {
      final result = await _channel.invokeMethod<bool>('isLocationMocked');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Check for known mock location apps
  static Future<bool> hasFakeGpsApp() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasFakeGpsApp');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Get device security flags
  static Future<Map<String, dynamic>> getSecurityFlags() async {
    try {
      final result = await _channel.invokeMethod<Map>('getSecurityFlags');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException {
      return {};
    }
  }

  /// Report security flags to backend
  static Future<void> reportSecurityFlags(Map<String, dynamic> flags) async {
    // This would call backend API
  }
}
