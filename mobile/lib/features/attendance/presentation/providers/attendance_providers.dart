import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:mobile/features/attendance/data/attendance_service.dart';
import 'package:mobile/features/attendance/data/datasource/attendance_data_source.dart';
import 'package:mobile/features/attendance/data/repository/attendance_repository.dart';
import 'package:mobile/features/attendance/data/attendance_flow_service.dart';
import 'package:mobile/features/attendance/data/local/offline_database.dart';
import 'package:mobile/features/attendance/data/local/elapsed_time_service.dart';
import 'package:mobile/features/attendance/data/local/offline_attendance_service.dart';
import 'package:mobile/features/face/presentation/providers/face_providers.dart';

final attendanceLocationServiceProvider = Provider<AttendanceLocationService>((ref) {
  return AttendanceLocationService();
});

final attendanceDataSourceProvider = Provider<AttendanceDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AttendanceDataSource(dio: dio);
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dataSource = ref.watch(attendanceDataSourceProvider);
  return AttendanceRepository(dataSource: dataSource);
});

final attendanceFlowServiceProvider = Provider<AttendanceFlowService>((ref) {
  final locationService = ref.watch(attendanceLocationServiceProvider);
  final faceDataSource = ref.watch(faceDataSourceProvider);
  final repository = ref.watch(attendanceRepositoryProvider);
  return AttendanceFlowService(
    locationService: locationService,
    faceDataSource: faceDataSource,
    repository: repository,
  );
});

// Offline providers
final offlineDatabaseProvider = Provider<OfflineDatabase>((ref) {
  return OfflineDatabase();
});

final elapsedTimeServiceProvider = Provider<ElapsedTimeService>((ref) {
  return ElapsedTimeService();
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final offlineAttendanceServiceProvider = Provider<OfflineAttendanceService>((ref) {
  final database = ref.watch(offlineDatabaseProvider);
  final elapsedTimeService = ref.watch(elapsedTimeServiceProvider);
  final repository = ref.watch(attendanceRepositoryProvider);
  final connectivity = ref.watch(connectivityProvider);
  
  return OfflineAttendanceService(
    database: database,
    elapsedTimeService: elapsedTimeService,
    repository: repository,
    connectivity: connectivity,
  );
});

// Pending count stream provider
final pendingCountProvider = StreamProvider<int>((ref) async* {
  final offlineService = ref.watch(offlineAttendanceServiceProvider);
  
  // Initial count
  yield await offlineService.getPendingCount();
  
  // Listen to connectivity changes and update count
  final connectivity = ref.watch(connectivityProvider);
  await for (final _ in connectivity.onConnectivityChanged) {
    yield await offlineService.getPendingCount();
  }
});

class AttendanceState {
  final bool isLoading;
  final bool isInsideArea;
  final double? distance;
  final String? errorMessage;
  final String? successMessage;

  AttendanceState({
    this.isLoading = false,
    this.isInsideArea = false,
    this.distance,
    this.errorMessage,
    this.successMessage,
  });

  AttendanceState copyWith({
    bool? isLoading,
    bool? isInsideArea,
    double? distance,
    String? errorMessage,
    String? successMessage,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      isInsideArea: isInsideArea ?? this.isInsideArea,
      distance: distance ?? this.distance,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceRepository repository;
  final AttendanceLocationService locationService;

  AttendanceNotifier({
    required this.repository,
    required this.locationService,
  }) : super(AttendanceState());

  Future<void> checkLocation({
    required double targetLat,
    required double targetLng,
    required double radiusMeters,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final position = await locationService.getCurrentPosition();
      final distance = locationService.calculateDistance(
        startLat: position.latitude,
        startLng: position.longitude,
        endLat: targetLat,
        endLng: targetLng,
      );

      final inside = distance <= radiusMeters;
      state = state.copyWith(
        isLoading: false,
        isInsideArea: inside,
        distance: distance,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> checkIn({
    required double lat,
    required double lng,
    required double faceScoreLocal,
    required String clientUuid,
    required Uint8List photo,
    required String deviceUid,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await repository.checkIn(
        lat: lat,
        lng: lng,
        faceScoreLocal: faceScoreLocal,
        clientUuid: clientUuid,
        photo: photo,
        deviceUid: deviceUid,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: res['message'] ?? 'Check-in berhasil',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> checkOut({
    required double lat,
    required double lng,
    required double faceScoreLocal,
    required String clientUuid,
    required Uint8List photo,
    required String deviceUid,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await repository.checkOut(
        lat: lat,
        lng: lng,
        faceScoreLocal: faceScoreLocal,
        clientUuid: clientUuid,
        photo: photo,
        deviceUid: deviceUid,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: res['message'] ?? 'Check-out berhasil',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  final loc = ref.watch(attendanceLocationServiceProvider);
  return AttendanceNotifier(repository: repo, locationService: loc);
});
