import 'dart:convert';
import 'dart:io';
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

  Future<List<Map<String, dynamic>>> fetchLogs() async {
    try {
      final response = await dio.get('/attendance/logs');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List).map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    } catch (e) {
      return [];
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
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'data': data};
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    } catch (e) {
      throw Exception('Gagal memuat ringkasan kehadiran: $e');
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
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'data': data};
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    } catch (e) {
      throw Exception('Gagal memuat statistik tim: $e');
    }
  }

  /// Get server time (B7 - for elapsed-realtime anchor)
  Future<int> fetchServerTime() async {
    try {
      final response = await dio.get('/time');
      final data = response.data as Map<String, dynamic>;
      final serverTime = data['server_time_millis'] ?? data['data']?['server_time'] ?? 0;
      if (serverTime is int) return serverTime;
      if (serverTime is double) return serverTime.toInt();
      return 0;
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
    required int anchorServerTimeMillis,
    required int anchorElapsedMillis,
    required int anchorBootCount,
    required int currentElapsedMillis,
    required int currentBootCount,
    String? deviceUid,
    String? photoPath,
  }) async {
    String? base64Photo;
    if (photoPath != null) {
      try {
        final file = File(photoPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          base64Photo = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      } catch (_) {}
    }

    final anchorServerTime = DateTime.fromMillisecondsSinceEpoch(anchorServerTimeMillis).toIso8601String();

    try {
      final response = await dio.post(
        '/attendance/sync',
        data: {
          'anchor': {
            'server_time': anchorServerTime,
            'elapsed_realtime': anchorElapsedMillis,
            'boot_count': anchorBootCount,
          },
          'boot_count': currentBootCount,
          'items': [
            {
              'client_uuid': clientUuid,
              'type': isCheckIn ? 'in' : 'out',
              'lat': lat,
              'lng': lng,
              'elapsed_realtime': currentElapsedMillis,
              'device_uid': deviceUid ?? 'mobile-device',
              'face_score_local': faceScoreLocal,
              if (base64Photo != null) 'photo': base64Photo,
            }
          ]
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Backend returns array of results: { success: true, data: [ { client_uuid, status, message, ... } ] }
        final results = data['data'];
        if (results is List && results.isNotEmpty) {
          final itemResult = results.first;
          if (itemResult is Map<String, dynamic>) {
            return itemResult;
          }
          return {'status': 'synced'};
        }
        return data;
      }
      return {'status': 'synced'};
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
