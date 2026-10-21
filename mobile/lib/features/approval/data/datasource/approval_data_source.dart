import 'package:dio/dio.dart';

class ApprovalDataSource {
  final Dio dio;

  ApprovalDataSource({required this.dio});

  /// Get inbox approval (leave requests + backup device attendance)
  Future<Map<String, dynamic>> getApprovalInbox({
    String? type, // 'leave' or 'attendance'
    String? status, // 'pending', 'approved', 'rejected'
  }) async {
    try {
      final response = await dio.get(
        '/approvals/inbox',
        queryParameters: {
          if (type != null) 'type': type,
          if (status != null) 'status': status,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Approve leave request
  Future<Map<String, dynamic>> approveLeaveRequest({
    required int requestId,
  }) async {
    try {
      final response = await dio.post(
        '/leave-requests/$requestId/approve',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Reject leave request
  Future<Map<String, dynamic>> rejectLeaveRequest({
    required int requestId,
    required String reason,
  }) async {
    try {
      final response = await dio.post(
        '/leave-requests/$requestId/reject',
        data: {'reason': reason},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Approve backup device attendance
  Future<Map<String, dynamic>> approveAttendance({
    required int attendanceId,
  }) async {
    try {
      final response = await dio.post(
        '/attendance/$attendanceId/approve',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  /// Reject backup device attendance
  Future<Map<String, dynamic>> rejectAttendance({
    required int attendanceId,
    required String reason,
  }) async {
    try {
      final response = await dio.post(
        '/attendance/$attendanceId/reject',
        data: {'reason': reason},
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
    if (e.response?.statusCode == 403) {
      return 'Anda tidak memiliki akses untuk menyetujui ini.';
    }
    if (e.response?.statusCode == 404) {
      return 'Data tidak ditemukan.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
    return e.response?.data['message'] ?? 'Terjadi kesalahan.';
  }
}
