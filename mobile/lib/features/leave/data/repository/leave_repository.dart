import 'package:mobile/features/leave/data/datasource/leave_data_source.dart';
import 'package:mobile/core/models/leave_models.dart';

class LeaveRepository {
  final LeaveDataSource dataSource;

  LeaveRepository({required this.dataSource});

  Future<LeaveBalanceModel> getBalance() async {
    final response = await dataSource.getLeaveBalance();
    return LeaveBalanceModel.fromJson(response['data'] ?? response);
  }

  Future<List<LeaveRequestModel>> getRequests({
    String? type,
    String? status,
  }) async {
    final list = await dataSource.getLeaveRequests(type: type, status: status);
    return list.map((json) => LeaveRequestModel.fromJson(json)).toList();
  }

  Future<void> submitRequest({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentPath,
  }) async {
    await dataSource.submitLeaveRequest(
      type: type,
      startDate: _formatDate(startDate),
      endDate: _formatDate(endDate),
      reason: reason,
      attachmentPath: attachmentPath,
    );
  }

  Future<void> cancelRequest(int requestId) async {
    await dataSource.cancelLeaveRequest(requestId: requestId);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
