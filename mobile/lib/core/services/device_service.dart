import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfo;

  static const _deviceUidKey = 'device_uid';
  static const _deviceNameKey = 'device_name';

  DeviceService({
    required this._storage,
    required this._deviceInfo,
  });

  /// Get or generate stable device UID
  Future<String> getDeviceUid() async {
    String? uid = await _storage.read(key: _deviceUidKey);
    
    if (uid == null || uid.isEmpty) {
      uid = const Uuid().v4();
      await _storage.write(key: _deviceUidKey, value: uid);
    }
    
    return uid;
  }

  /// Get device name (model + manufacturer)
  Future<String> getDeviceName() async {
    String? cached = await _storage.read(key: _deviceNameKey);
    
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    String name = 'Unknown Device';
    
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      name = '${androidInfo.manufacturer} ${androidInfo.model}';
      await _storage.write(key: _deviceNameKey, value: name);
    } catch (e) {
      // Fallback if info not available
      name = 'Android Device';
    }

    return name;
  }

  /// Get device info for registration
  Future<Map<String, String>> getDeviceInfo() async {
    final uid = await getDeviceUid();
    final name = await getDeviceName();
    
    return {
      'device_uid': uid,
      'device_name': name,
    };
  }

  /// Clear device data (for testing/reset)
  Future<void> clearDeviceData() async {
    await _storage.delete(key: _deviceUidKey);
    await _storage.delete(key: _deviceNameKey);
  }
}
