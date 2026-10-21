import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:mobile/features/leave/data/datasource/leave_data_source.dart';
import 'package:mobile/features/leave/data/repository/leave_repository.dart';
import 'package:mobile/core/models/leave_models.dart';

final leaveDataSourceProvider = Provider<LeaveDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return LeaveDataSource(dio: dio);
});

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  final dataSource = ref.watch(leaveDataSourceProvider);
  return LeaveRepository(dataSource: dataSource);
});

// Leave balance provider
final leaveBalanceProvider = FutureProvider<LeaveBalanceModel>((ref) async {
  final repository = ref.watch(leaveRepositoryProvider);
  return await repository.getBalance();
});

// Leave requests provider
final leaveRequestsProvider = FutureProvider.family<List<LeaveRequestModel>, LeaveRequestsParams>(
  (ref, params) async {
    final repository = ref.watch(leaveRepositoryProvider);
    return await repository.getRequests(
      type: params.type,
      status: params.status,
    );
  },
);

// Leave submission notifier
final leaveSubmissionProvider = StateNotifierProvider<LeaveSubmissionNotifier, AsyncValue<void>>(
  (ref) => LeaveSubmissionNotifier(ref),
);

class LeaveSubmissionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  LeaveSubmissionNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> submitRequest({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentPath,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(leaveRepositoryProvider);
      await repository.submitRequest(
        type: type,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        attachmentPath: attachmentPath,
      );
      state = const AsyncValue.data(null);
      
      // Refresh data
      ref.invalidate(leaveRequestsProvider);
      ref.invalidate(leaveBalanceProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> cancelRequest(int requestId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(leaveRepositoryProvider);
      await repository.cancelRequest(requestId);
      state = const AsyncValue.data(null);
      
      // Refresh data
      ref.invalidate(leaveRequestsProvider);
      ref.invalidate(leaveBalanceProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class LeaveRequestsParams {
  final String? type;
  final String? status;

  LeaveRequestsParams({this.type, this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveRequestsParams &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          status == other.status;

  @override
  int get hashCode => type.hashCode ^ status.hashCode;
}
