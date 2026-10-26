import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:mobile/features/notification/data/datasource/notification_data_source.dart';
import 'package:mobile/core/models/notification_model.dart';

final notificationDataSourceProvider = Provider<NotificationDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationDataSource(dio: dio);
});

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final dataSource = ref.watch(notificationDataSourceProvider);
  final list = await dataSource.getNotifications();
  return list.map((json) => NotificationModel.fromJson(json)).toList();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.when(
    data: (items) => items.where((e) => !e.isRead).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

final notificationActionProvider = StateNotifierProvider<NotificationActionNotifier, AsyncValue<void>>(
  (ref) => NotificationActionNotifier(ref),
);

class NotificationActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  NotificationActionNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> markAsRead(int notificationId) async {
    state = const AsyncValue.loading();
    try {
      final dataSource = ref.read(notificationDataSourceProvider);
      await dataSource.markAsRead(notificationId);
      state = const AsyncValue.data(null);
      ref.invalidate(notificationsProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      final dataSource = ref.read(notificationDataSourceProvider);
      await dataSource.markAllAsRead();
      state = const AsyncValue.data(null);
      ref.invalidate(notificationsProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
