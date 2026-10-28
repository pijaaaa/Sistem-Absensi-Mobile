import 'dart:typed_data';
import 'package:mobile/features/attendance/data/datasource/attendance_data_source.dart';

class AttendanceRepository {
  final AttendanceDataSource dataSource;

  AttendanceRepository({required this.dataSource});

  Future<Map<String, dynamic>> checkIn({
    required double lat,
    required double lng,
    required double faceScoreLocal,
    required String clientUuid,
    required String deviceUid,
    required Uint8List photo,
    bool isBackupDevice = false,
  }) async {
    return await dataSource.checkIn(
      lat: lat,
      lng: lng,
      faceScoreLocal: faceScoreLocal,
      clientUuid: clientUuid,
      deviceUid: deviceUid,
      photo: photo,
      isBackupDevice: isBackupDevice,
    );
  }

  Future<Map<String, dynamic>> checkOut({
    required double lat,
    required double lng,
    required double faceScoreLocal,
    required String clientUuid,
    required String deviceUid,
    required Uint8List photo,
  }) async {
    return await dataSource.checkOut(
      lat: lat,
      lng: lng,
      faceScoreLocal: faceScoreLocal,
      clientUuid: clientUuid,
      deviceUid: deviceUid,
      photo: photo,
    );
  }

  Future<Map<String, dynamic>> getSummary() async {
    return await dataSource.fetchSummary();
  }

  /// Get server time for elapsed-realtime anchor (B7)
  Future<int> getServerTime() async {
    return await dataSource.fetchServerTime();
  }

  /// Sync offline attendance batch (B7)
  Future<Map<String, dynamic>> syncOfflineAttendance({
    required String clientUuid,
    required bool isCheckIn,
    required double lat,
    required double lng,
    required double faceScoreLocal,
    required int anchorServerTimeMillis,
    required int anchorElapsedMillis,
    required int anchorBootCount,
    required int currentElapsedMillis,
    required int currentBootCount,
    String? deviceUid,
    String? photoPath,
  }) async {
    return await dataSource.syncOfflineAttendance(
      clientUuid: clientUuid,
      isCheckIn: isCheckIn,
      lat: lat,
      lng: lng,
      faceScoreLocal: faceScoreLocal,
      anchorServerTimeMillis: anchorServerTimeMillis,
      anchorElapsedMillis: anchorElapsedMillis,
      anchorBootCount: anchorBootCount,
      currentElapsedMillis: currentElapsedMillis,
      currentBootCount: currentBootCount,
      deviceUid: deviceUid,
      photoPath: photoPath,
    );
  }
}
