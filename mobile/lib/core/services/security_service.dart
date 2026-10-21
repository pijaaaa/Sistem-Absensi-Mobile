import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/services/native_security_service.dart';

class SecurityService {
  final FlutterSecureStorage storage;

  SecurityService({required this.storage});

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

  /// Clear security cache (on logout)
  Future<void> clearSecurityData() async {
    await storage.delete(key: 'last_boot_check');
  }
}

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(storage: const FlutterSecureStorage());
});
