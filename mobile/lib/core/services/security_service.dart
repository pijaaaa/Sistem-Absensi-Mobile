import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:mobile/core/services/native_security_service.dart';

class SecurityService {
  final FlutterSecureStorage storage;
  final Dio? dio;

  SecurityService({required this.storage, this.dio});

  /// Check for root access, emulator, or jailbreak
  Future<bool> isDeviceCompromised() async {
    bool compromised = false;

    // Check native security flags
    try {
      final flags = await NativeSecurityService.getSecurityFlags();
      compromised = (flags['is_rooted'] as bool? ?? false) ||
          (flags['is_emulator'] as bool? ?? false) ||
          (flags['is_mock_location_enabled'] as bool? ?? false) ||
          (flags['is_location_mocked'] as bool? ?? false) ||
          (flags['has_fake_gps_app'] as bool? ?? false);
    } catch (_) {}

    // Check for time tampering
    compromised = compromised || await checkTimeTampering();

    return compromised;
  }

  /// Check for suspicious time changes
  Future<bool> checkTimeTampering() async {
    final now = DateTime.now();
    final lastCheckStr = await storage.read(key: 'last_boot_check');
    
    if (lastCheckStr != null) {
      final lastCheck = DateTime.parse(lastCheckStr);
      // Check if time went backwards (tampering)
      if (now.isBefore(lastCheck)) {
        return true;
      }
    }
    
    await storage.write(key: 'last_boot_check', value: now.toIso8601String());
    return false;
  }

  /// Report security flags to backend for audit
  Future<void> reportSecurityFlags() async {
    if (dio == null) return;
    
    try {
      final flags = await NativeSecurityService.getSecurityFlags();
      final timeTampered = await checkTimeTampering();
      
      await dio!.post(
        '/security/report',
        data: {
          'is_rooted': flags['is_rooted'] ?? false,
          'is_emulator': flags['is_emulator'] ?? false,
          'is_mock_location_enabled': flags['is_mock_location_enabled'] ?? false,
          'is_location_mocked': flags['is_location_mocked'] ?? false,
          'has_fake_gps_app': flags['has_fake_gps_app'] ?? false,
          'time_tampered': timeTampered,
          'reported_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {
      // Silently fail - security reporting is non-critical
    }
  }

  /// Clear security cache (on logout)
  Future<void> clearSecurityData() async {
    await storage.delete(key: 'last_boot_check');
  }
}

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(storage: const FlutterSecureStorage());
});

final securityServiceWithDioProvider = Provider<SecurityService>((ref) {
  final dio = ref.watch(dioProvider);
  return SecurityService(storage: const FlutterSecureStorage(), dio: dio);
});
