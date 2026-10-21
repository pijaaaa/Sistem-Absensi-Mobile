import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:mobile/features/approval/data/datasource/approval_data_source.dart';
import 'package:mobile/features/approval/data/repository/approval_repository.dart';
import 'package:mobile/core/models/approval_item_model.dart';

final approvalDataSourceProvider = Provider<ApprovalDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ApprovalDataSource(dio: dio);
});

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  final dataSource = ref.watch(approvalDataSourceProvider);
  return ApprovalRepository(dataSource: dataSource);
});

// Approval inbox provider
final approvalInboxProvider = FutureProvider.family<List<ApprovalItemModel>, ApprovalInboxParams>(
  (ref, params) async {
    final repository = ref.watch(approvalRepositoryProvider);
    return await repository.getInbox(
      type: params.type,
      status: params.status,
    );
  },
);

// Approval action notifier
final approvalActionProvider = StateNotifierProvider<ApprovalActionNotifier, AsyncValue<void>>(
  (ref) => ApprovalActionNotifier(ref),
);

class ApprovalActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ApprovalActionNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> approveLeaveRequest(int requestId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(approvalRepositoryProvider);
      await repository.approveLeaveRequest(requestId);
      state = const AsyncValue.data(null);
      
      // Refresh inbox
      ref.invalidate(approvalInboxProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> rejectLeaveRequest(int requestId, String reason) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(approvalRepositoryProvider);
      await repository.rejectLeaveRequest(requestId, reason);
      state = const AsyncValue.data(null);
      
      // Refresh inbox
      ref.invalidate(approvalInboxProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> approveAttendance(int attendanceId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(approvalRepositoryProvider);
      await repository.approveAttendance(attendanceId);
      state = const AsyncValue.data(null);
      
      // Refresh inbox
      ref.invalidate(approvalInboxProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> rejectAttendance(int attendanceId, String reason) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(approvalRepositoryProvider);
      await repository.rejectAttendance(attendanceId, reason);
      state = const AsyncValue.data(null);
      
      // Refresh inbox
      ref.invalidate(approvalInboxProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class ApprovalInboxParams {
  final String? type;
  final String? status;

  ApprovalInboxParams({this.type, this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalInboxParams &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          status == other.status;

  @override
  int get hashCode => type.hashCode ^ status.hashCode;
}
