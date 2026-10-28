import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';

class NotificationDataSource {
  final Dio dio;

  NotificationDataSource({required this.dio});

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await dio.get('/notifications');
      final data = response.data;
      if (data is Map) {
        return (data['data'] as List? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
      if (data is List) {
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await dio.post('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  Future<Map<String, bool>> getPreferences() async {
    try {
      final response = await dio.get(ApiConstants.notificationPreferences);
      final data = response.data as Map<String, dynamic>;
      final prefs = data['data'] as Map<String, dynamic>? ?? {};
      return prefs.map((k, v) => MapEntry(k, v == true || v == 1));
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  Future<void> updatePreferences(Map<String, bool> preferences) async {
    try {
      await dio.put(ApiConstants.notificationPreferences, data: {
        'preferences': preferences,
      });
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  String _formatError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
    return 'Terjadi kesalahan.';
  }
}
