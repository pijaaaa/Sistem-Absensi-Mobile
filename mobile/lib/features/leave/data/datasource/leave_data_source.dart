import 'package:dio/dio.dart';

class LeaveDataSource {
  final Dio dio;

  LeaveDataSource({required this.dio});

  /// Get leave balance for current user
  Future<Map<String, dynamic>> getLeaveBalance() async {
    try {
      final response = await dio.get('/leave/balance');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Get leave requests (history)
  Future<List<Map<String, dynamic>>> getLeaveRequests({
    String? type, // 'cuti', 'sakit', 'izin', 'dinas'
    String? status, // 'pending', 'approved', 'rejected'
  }) async {
    try {
      final response = await dio.get(
        '/leave/requests',
        queryParameters: {
          if (type != null) 'type': type,
          if (status != null) 'status': status,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (data['data'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Submit leave request
  Future<Map<String, dynamic>> submitLeaveRequest({
    required String type, // 'cuti', 'sakit', 'izin', 'dinas'
    required String startDate, // YYYY-MM-DD
    required String endDate, // YYYY-MM-DD
    required String reason,
    String? attachmentPath, // For 'sakit'
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'type': type,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
        if (attachmentPath != null)
          'attachment': await MultipartFile.fromFile(attachmentPath),
      });

      final response = await dio.post(
        '/leave/requests',
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Cancel leave request (if still pending)
  Future<Map<String, dynamic>> cancelLeaveRequest({
    required int requestId,
  }) async {
    try {
      final response = await dio.delete('/leave/requests/$requestId');
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
    if (e.response?.statusCode == 400) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Permintaan tidak valid.';
    }
    if (e.response?.statusCode == 409) {
      return 'Terjadi konflik dengan pengajuan lain.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
    return e.response?.data['message'] ?? 'Terjadi kesalahan.';
  }
}
