import 'package:mobile/features/approval/data/datasource/approval_data_source.dart';
import 'package:mobile/core/models/approval_item_model.dart';

class ApprovalRepository {
  final ApprovalDataSource dataSource;

  ApprovalRepository({required this.dataSource});

  Future<List<ApprovalItemModel>> getInbox({
    String? type,
    String? status,
  }) async {
    final response = await dataSource.getApprovalInbox(
      type: type,
      status: status,
    );
    
    final items = (response['data'] as List? ?? [])
        .map((e) => ApprovalItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return items;
  }

  Future<void> approveLeaveRequest(int requestId) async {
    await dataSource.approveLeaveRequest(requestId: requestId);
  }

  Future<void> rejectLeaveRequest(int requestId, String reason) async {
    await dataSource.rejectLeaveRequest(
      requestId: requestId,
      reason: reason,
    );
  }

  Future<void> approveAttendance(int attendanceId) async {
    await dataSource.approveAttendance(attendanceId: attendanceId);
  }

  Future<void> rejectAttendance(int attendanceId, String reason) async {
    await dataSource.rejectAttendance(
      attendanceId: attendanceId,
      reason: reason,
    );
  }
}
