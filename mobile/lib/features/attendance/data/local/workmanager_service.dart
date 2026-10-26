import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:mobile/features/attendance/data/local/offline_database.dart';
import 'package:mobile/features/attendance/data/local/elapsed_time_service.dart';
import 'package:mobile/features/attendance/data/local/offline_attendance_service.dart';
import 'package:mobile/features/attendance/data/repository/attendance_repository.dart';
import 'package:mobile/features/attendance/data/datasource/attendance_data_source.dart';

/// Background task untuk auto-sync offline attendance
const String syncTaskName = "com.bsp.absensi.syncOfflineAttendance";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == syncTaskName) {
        // Initialize services
        final database = OfflineDatabase();
        final elapsedTimeService = ElapsedTimeService();
        final connectivity = Connectivity();
        
        // Check if online
        final result = await connectivity.checkConnectivity();
        final isOnline = result.contains(ConnectivityResult.mobile) || 
                        result.contains(ConnectivityResult.wifi) ||
                        result.contains(ConnectivityResult.ethernet);
        
         if (!isOnline) {
          return true; // Retry later
        }

        // Initialize repository (need token from storage)
        // For now, skip if no token - real implementation needs secure storage
        final dio = Dio();
        dio.options.baseUrl = 'http://localhost:8000/api'; // Dummy for background task
        final dataSource = AttendanceDataSource(dio: dio);
        final repository = AttendanceRepository(dataSource: dataSource);

        final offlineService = OfflineAttendanceService(
          database: database,
          elapsedTimeService: elapsedTimeService,
          repository: repository,
          connectivity: connectivity,
        );

        // Sync pending attendances
        final syncResult = await offlineService.syncPendingAttendances();

        return syncResult.success;
      }

      return true;
    } catch (e) {
      debugPrint('Background sync error: $e');
      return false;
    }
  });
}

/// Initialize workmanager for background sync
class WorkManagerService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Register periodic sync task (runs every 15 minutes when conditions met)
  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
    );
  }

  /// Cancel sync task
  static Future<void> cancelSync() async {
    await Workmanager().cancelByUniqueName(syncTaskName);
  }

  /// Trigger one-time sync immediately
  static Future<void> triggerOneTimeSync() async {
    await Workmanager().registerOneOffTask(
      "${syncTaskName}_oneoff",
      syncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
