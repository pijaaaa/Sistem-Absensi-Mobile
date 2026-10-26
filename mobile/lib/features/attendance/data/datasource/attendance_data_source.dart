import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class AttendanceDataSource {
  final Dio dio;

  AttendanceDataSource({required this.dio});

  Future<Map<String, dynamic>> checkIn({
    required double lat,
    required double lng,
    required double faceScoreLocal,
    required String clientUuid,
    required Uint8List photo,
    required String deviceUid,
    bool isBackupDevice = false,
  }) async {
    final formData = FormData.fromMap({
      'lat': lat,
      'lng': lng,
      'face_score_local': faceScoreLocal,
      'client_uuid': clientUuid,
      'device_uid': deviceUid,
      'is_backup_device': isBackupDevice,
      'photo': MultipartFile.fromBytes(
        photo,
        filename: 'face_$clientUuid.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    try {
      final response = await dio.post(
        '/attendance/check-in',
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  Future<Map<String, dynamic>> checkOut({
    required double lat,
    required double lng,
    required double faceScoreLocal,
    required String clientUuid,
    required Uint8List photo,
    required String deviceUid,
  }) async {
    final formData = FormData.fromMap({
      'lat': lat,
      'lng': lng,
      'face_score_local': faceScoreLocal,
      'client_uuid': clientUuid,
      'device_uid': deviceUid,
      'photo': MultipartFile.fromBytes(
        photo,
        filename: 'face_$clientUuid.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    try {
      final response = await dio.post(
        '/attendance/check-out',
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  Future<Map<String, dynamic>> fetchSummary({int? year, int? month}) async {
    try {
      final response = await dio.get(
        '/attendance/summary',
        queryParameters: {
          'year': ?year,
          'month': ?month,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Get monthly summary (same endpoint as fetchSummary, kept for compatibility)
  @Deprecated('Use fetchSummary instead')
  Future<Map<String, dynamic>> fetchMonthlySummary({
    int? year,
    int? month,
  }) async {
    return fetchSummary(year: year, month: month);
  }

  /// Get team statistics (for manager)
  Future<Map<String, dynamic>> fetchTeamStats() async {
    try {
      final response = await dio.get('/team-stats');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Get server time (B7 - for elapsed-realtime anchor)
  Future<int> fetchServerTime() async {
    try {
      final response = await dio.get('/time');
      final data = response.data as Map<String, dynamic>;
      final serverTime = data['server_time_millis'] ?? data['data']?['server_time'] ?? 0;
      return serverTime as int;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Sync offline attendance batch (B7)
  Future<Map<String, dynamic>> syncOfflineAttendance({
    required String clientUuid,
    required bool isCheckIn,
    required double lat,
    required double lng,
    required double faceScoreLocal,
    required int calculatedServerTimeMillis,
    required bool isSuspect,
    String? deviceUid,
    bool isBackupDevice = false,
  }) async {
    try {
      final response = await dio.post(
        '/attendance/sync',
        data: {
          'client_uuid': clientUuid,
          'is_check_in': isCheckIn,
          'lat': lat,
          'lng': lng,
          'face_score_local': faceScoreLocal,
          'calculated_server_time_millis': calculatedServerTimeMillis,
          'is_suspect': isSuspect,
          'device_uid': deviceUid,
          'is_backup_device': isBackupDevice,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  String _formatError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
        final first = (data['errors'] as Map).values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
        return first.toString();
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }
    if (e.response?.statusCode == 401) return 'NIP/email atau password salah.';
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Pastikan jaringan Anda menyala.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
