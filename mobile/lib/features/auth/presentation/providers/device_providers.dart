import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:mobile/core/services/device_service.dart';
import 'package:mobile/features/auth/data/datasource/device_data_source.dart';
import 'package:mobile/features/auth/data/repository/device_repository.dart';
import 'package:mobile/core/models/device_model.dart';

final deviceInfoPluginProvider = Provider<DeviceInfoPlugin>((ref) {
  return DeviceInfoPlugin();
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  final deviceInfo = ref.watch(deviceInfoPluginProvider);
  return DeviceService(storage: storage, deviceInfo: deviceInfo);
});

final deviceDataSourceProvider = Provider<DeviceDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return DeviceDataSource(dio: dio);
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final dataSource = ref.watch(deviceDataSourceProvider);
  final deviceService = ref.watch(deviceServiceProvider);
  final storage = ref.watch(flutterSecureStorageProvider);
  return DeviceRepository(
    dataSource: dataSource,
    deviceService: deviceService,
    storage: storage,
  );
});

// Current device info provider
final currentDeviceInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return await deviceService.getDeviceInfo();
});

// User devices list provider
final userDevicesProvider = FutureProvider<List<DeviceModel>>((ref) async {
  final dataSource = ref.watch(deviceDataSourceProvider);
  final response = await dataSource.getDevices();
  return response.map((json) => DeviceModel.fromJson(json)).toList();
});

// Device status provider
final deviceStatusProvider = FutureProvider<DeviceModel?>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  final dataSource = ref.watch(deviceDataSourceProvider);
  
  try {
    final deviceInfo = await deviceService.getDeviceInfo();
    final deviceUid = deviceInfo['device_uid']!;
    
    final response = await dataSource.checkDeviceStatus(deviceUid: deviceUid);
    if (response['device'] != null) {
      return DeviceModel.fromJson(response['device'] as Map<String, dynamic>);
    }
  } catch (e) {
    // Device not registered yet
    return null;
  }
  
  return null;
});
