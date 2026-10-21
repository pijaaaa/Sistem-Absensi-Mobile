import 'package:dio/dio.dart';

class AttendanceDataSource {
  final Dio dio;

  AttendanceDataSource({required this.dio});

  Future<Map<String, dynamic>> checkIn({
    required double lat,
    required double lng,
    required double faceScoreLocal,
    required String clientUuid,
    String? deviceUid,
    bool isBackupDevice = false,
  }) async {
    try {
      final response = await dio.post(
        '/attendance/check-in',
        data: {
          'lat': lat,
          'lng': lng,
          'face_score_local': faceScoreLocal,
          'client_uuid': clientUuid,
          'device_uid': deviceUid,
          'is_backup_device': isBackupDevice,
        },
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
    String? deviceUid,
  }) async {
    try {
      final response = await dio.post(
        '/attendance/check-out',
        data: {
          'lat': lat,
          'lng': lng,
          'face_score_local': faceScoreLocal,
          'client_uuid': clientUuid,
          'device_uid': deviceUid,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  Future<Map<String, dynamic>> fetchSummary() async {
    try {
      final response = await dio.get('/attendance/summary');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Get detailed monthly summary with calendar
  Future<Map<String, dynamic>> fetchMonthlySummary({
    int? year,
    int? month,
  }) async {
    try {
      final response = await dio.get(
        '/attendance/summary/monthly',
        queryParameters: {
          if (year != null) 'year': year,
          if (month != null) 'month': month,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Get team statistics (for manager)
  Future<Map<String, dynamic>> fetchTeamStats() async {
    try {
      final response = await dio.get('/attendance/team-stats');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Get server time (B7 - for elapsed-realtime anchor)
  Future<int> fetchServerTime() async {
    try {
      final response = await dio.get('/attendance/server-time');
      final data = response.data as Map<String, dynamic>;
      return data['server_time_millis'] as int;
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
        '/attendance/sync-offline',
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
    if (e.response?.statusCode == 422) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
    return e.response?.data['message'] ?? 'Terjadi kesalahan saat absen.';
  }
}
