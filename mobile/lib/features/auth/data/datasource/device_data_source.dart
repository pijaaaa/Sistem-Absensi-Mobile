import 'package:dio/dio.dart';

class DeviceDataSource {
  final Dio dio;

  DeviceDataSource({required this.dio});

  /// Register device (login from new device)
  Future<Map<String, dynamic>> registerDevice({
    required String deviceUid,
    required String deviceName,
    required String type, // 'primary' or 'backup'
  }) async {
    try {
      final response = await dio.post(
        '/devices/register',
        data: {
          'device_uid': deviceUid,
          'name': deviceName,
          'type': type,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Check device status
  Future<Map<String, dynamic>> checkDeviceStatus({
    required String deviceUid,
  }) async {
    try {
      final response = await dio.get(
        '/devices/status',
        queryParameters: {'device_uid': deviceUid},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Get list of user devices
  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final response = await dio.get('/devices');
      final data = response.data as Map<String, dynamic>;
      return (data['data'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  String _formatError(DioException e) {
    if (e.response?.statusCode == 422) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    if (e.response?.statusCode == 403) {
      return 'Tidak diizinkan. Hubungi admin untuk reset perangkat.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
    return e.response?.data['message'] ?? 'Terjadi kesalahan pada perangkat.';
  }
}
