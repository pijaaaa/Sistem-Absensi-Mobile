import 'package:dio/dio.dart';

class NotificationDataSource {
  final Dio dio;

  NotificationDataSource({required this.dio});

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await dio.get('/notifications');
      final data = response.data as Map<String, dynamic>;
      return (data['data'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
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

  String _formatError(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
    return e.response?.data['message'] ?? 'Terjadi kesalahan.';
  }
}
