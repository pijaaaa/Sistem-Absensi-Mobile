import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/data/datasource/device_data_source.dart';
import 'package:mobile/core/services/device_service.dart';
import 'package:mobile/core/models/device_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants/storage_keys.dart';

class DeviceRepository {
  final DeviceDataSource dataSource;
  final DeviceService deviceService;
  final FlutterSecureStorage storage;

  DeviceRepository({
    required this.dataSource,
    required this.deviceService,
    required this.storage,
  });

  /// Check and register device if needed
  /// Returns: device status and whether it needs approval
  Future<DeviceRegistrationResult> checkAndRegisterDevice() async {
    final deviceInfo = await deviceService.getDeviceInfo();
    final deviceUid = deviceInfo['device_uid']!;
    final deviceName = deviceInfo['device_name']!;

    try {
      // Check if device is already registered
      final response = await dataSource.checkDeviceStatus(deviceUid: deviceUid);
      final device = DeviceModel.fromJson(response['device'] as Map<String, dynamic>);

      // Save device type and status locally
      await storage.write(key: StorageKeys.deviceType, value: device.type);
      await storage.write(key: StorageKeys.deviceStatus, value: device.status);

      return DeviceRegistrationResult(
        device: device,
        needsRegistration: false,
        isBackupDevice: device.isBackup,
      );
    } catch (e) {
      // Device not registered, need to register
      return DeviceRegistrationResult(
        device: null,
        needsRegistration: true,
        isBackupDevice: false,
      );
    }
  }

  /// Register device as primary or backup
  Future<DeviceModel> registerDevice({required bool asBackup}) async {
    final deviceInfo = await deviceService.getDeviceInfo();
    final deviceUid = deviceInfo['device_uid']!;
    final deviceName = deviceInfo['device_name']!;

    final response = await dataSource.registerDevice(
      deviceUid: deviceUid,
      deviceName: deviceName,
      type: asBackup ? 'backup' : 'primary',
    );

    final device = DeviceModel.fromJson(response['device'] as Map<String, dynamic>);

    // Save device type and status locally
    await storage.write(key: StorageKeys.deviceType, value: device.type);
    await storage.write(key: StorageKeys.deviceStatus, value: device.status);

    return device;
  }

  /// Get current device UID
  Future<String> getCurrentDeviceUid() async {
    final deviceInfo = await deviceService.getDeviceInfo();
    return deviceInfo['device_uid']!;
  }

  /// Check if this is a backup device
  Future<bool> isBackupDevice() async {
    final type = await storage.read(key: StorageKeys.deviceType);
    return type == 'backup';
  }
}

class DeviceRegistrationResult {
  final DeviceModel? device;
  final bool needsRegistration;
  final bool isBackupDevice;

  DeviceRegistrationResult({
    required this.device,
    required this.needsRegistration,
    required this.isBackupDevice,
  });
}
