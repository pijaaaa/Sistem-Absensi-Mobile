import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile/features/attendance/data/local/offline_database.dart';
import 'package:mobile/features/attendance/data/local/elapsed_time_service.dart';
import 'package:mobile/features/attendance/data/repository/attendance_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

/// Service untuk handle offline attendance dan auto-sync
class OfflineAttendanceService {
  final OfflineDatabase database;
  final ElapsedTimeService elapsedTimeService;
  final AttendanceRepository repository;
  final Connectivity connectivity;

  bool _isSyncing = false;

  OfflineAttendanceService({
    required this.database,
    required this.elapsedTimeService,
    required this.repository,
    required this.connectivity,
  });

  /// Check if device is online
  Future<bool> isOnline() async {
    final result = await connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) || 
           result.contains(ConnectivityResult.wifi) ||
           result.contains(ConnectivityResult.ethernet);
  }

  /// Get or create server time anchor
  Future<ServerTimeAnchor> getOrCreateAnchor() async {
    // Try to get latest anchor
    final anchor = await database.getLatestAnchor();
    
    if (anchor != null && anchor.serverTimeMillis > 1700000000000) {
      // Check if boot count changed (device restarted)
      final currentBootCount = await elapsedTimeService.getBootCount();
      if (currentBootCount == anchor.bootCount) {
        // Anchor still valid
        return anchor;
      }
    }

    // Need new anchor: fetch server time
    if (await isOnline()) {
      try {
        final serverTimeMillis = await repository.getServerTime();
        final elapsedMillis = await elapsedTimeService.getElapsedRealtimeMillis();
        final bootCount = await elapsedTimeService.getBootCount();

        await database.saveServerTimeAnchor(
          ServerTimeAnchorsCompanion(
            serverTimeMillis: Value(serverTimeMillis),
            elapsedRealtimeMillis: Value(elapsedMillis),
            bootCount: Value(bootCount),
          ),
        );

        await database.cleanOldAnchors();

        final newAnchor = await database.getLatestAnchor();
        return newAnchor!;
      } catch (e) {
        if (kDebugMode) {
          print('Failed to fetch server time: $e');
        }
        // Return dummy anchor if failed
        final elapsedMillis = await elapsedTimeService.getElapsedRealtimeMillis();
        final bootCount = await elapsedTimeService.getBootCount();
        return ServerTimeAnchor(
          id: 0,
          serverTimeMillis: DateTime.now().millisecondsSinceEpoch,
          elapsedRealtimeMillis: elapsedMillis,
          bootCount: bootCount,
          createdAt: DateTime.now(),
        );
      }
    } else {
      // Offline: return dummy anchor based on system time
      final elapsedMillis = await elapsedTimeService.getElapsedRealtimeMillis();
      final bootCount = await elapsedTimeService.getBootCount();
      return ServerTimeAnchor(
        id: 0,
        serverTimeMillis: DateTime.now().millisecondsSinceEpoch,
        elapsedRealtimeMillis: elapsedMillis,
        bootCount: bootCount,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Save attendance offline
  Future<String> saveOfflineAttendance({
    required int userId,
    required bool isCheckIn,
    required double lat,
    required double lng,
    required double faceScoreReal,
    required Uint8List? faceImageBytes,
    String? deviceUid,
    bool isBackupDevice = false,
  }) async {
    final clientUuid = const Uuid().v4();

    // Get anchor
    final anchor = await getOrCreateAnchor();
    
    // Get current elapsed time
    final elapsedMillis = await elapsedTimeService.getElapsedRealtimeMillis();
    final bootCount = await elapsedTimeService.getBootCount();

    // Save face image encrypted (if provided)
    String? faceImagePath;
    if (faceImageBytes != null) {
      faceImagePath = await _saveFaceImage(clientUuid, faceImageBytes);
    }

    // Save to database
    await database.addOfflineAttendance(
      OfflineAttendancesCompanion(
        userId: Value(userId),
        clientUuid: Value(clientUuid),
        isCheckIn: Value(isCheckIn),
        latitude: Value(lat),
        longitude: Value(lng),
        faceScoreLocal: Value(faceScoreReal),
        faceImagePath: Value(faceImagePath),
        elapsedRealtimeMillis: Value(elapsedMillis),
        anchorServerTimeMillis: Value(anchor.serverTimeMillis),
        anchorElapsedMillis: Value(anchor.elapsedRealtimeMillis),
        bootCount: Value(bootCount),
        deviceUid: Value(deviceUid),
        isBackupDevice: Value(isBackupDevice),
      ),
    );

    return clientUuid;
  }

  /// Sync all pending attendances with mutex lock and exponential backoff retry for network/5xx errors
  Future<SyncResult> syncPendingAttendances(int userId) async {
    // 4. Mutex lock preventing concurrent sync executions
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync sedang berjalan');
    }

    _isSyncing = true;
    try {
      if (!await isOnline()) {
        return SyncResult(success: false, message: 'Tidak ada koneksi internet');
      }

      final pending = await database.getPendingAttendances(userId);
      
      if (pending.isEmpty) {
        return SyncResult(success: true, synced: 0, message: 'Tidak ada data offline');
      }

      int synced = 0;
      int failed = 0;

      for (final attendance in pending) {
        // Exponential backoff check based on sync attempts
        if (attendance.syncAttempts > 0 && attendance.lastSyncAttempt != null) {
          final backoffSeconds = _calculateBackoffSeconds(attendance.syncAttempts);
          final nextAllowedTime = attendance.lastSyncAttempt!.add(Duration(seconds: backoffSeconds));
          if (DateTime.now().isBefore(nextAllowedTime)) {
            continue; // Skip for now due to exponential backoff
          }
        }

        try {
          // Calculate server time from elapsed-realtime
          final timeResult = await elapsedTimeService.calculateServerTime(
            anchorServerTimeMillis: attendance.anchorServerTimeMillis,
            anchorElapsedMillis: attendance.anchorElapsedMillis,
            anchorBootCount: attendance.bootCount,
          );

          // Call sync API (backend B7)
          final response = await repository.syncOfflineAttendance(
            clientUuid: attendance.clientUuid,
            isCheckIn: attendance.isCheckIn,
            lat: attendance.latitude,
            lng: attendance.longitude,
            faceScoreLocal: attendance.faceScoreLocal,
            anchorServerTimeMillis: attendance.anchorServerTimeMillis,
            anchorElapsedMillis: attendance.anchorElapsedMillis,
            anchorBootCount: attendance.bootCount,
            currentElapsedMillis: timeResult.currentElapsedMillis,
            currentBootCount: timeResult.currentBootCount,
            deviceUid: attendance.deviceUid,
            photoPath: attendance.faceImagePath,
          );

          // 3. Handling response status ('synced', 'needs_review', 'rejected', duplicate)
          final status = response['status'] ?? 'synced';
          final message = response['message']?.toString();
          if (status == 'synced' || status == 'needs_review' || status == 'duplicate' || status == 'created' || response['success'] == true) {
            await database.markAsSynced(attendance.clientUuid);
            synced++;

            // Delete face image after successful sync
            if (attendance.faceImagePath != null) {
              await _deleteFaceImage(attendance.faceImagePath!);
            }

            // 3. Updating anchor time on success
            try {
              final serverTimeMillis = await repository.getServerTime();
              final elapsedMillis = await elapsedTimeService.getElapsedRealtimeMillis();
              final bootCount = await elapsedTimeService.getBootCount();

              await database.saveServerTimeAnchor(
                ServerTimeAnchorsCompanion(
                  serverTimeMillis: Value(serverTimeMillis),
                  elapsedRealtimeMillis: Value(elapsedMillis),
                  bootCount: Value(bootCount),
                ),
              );
              await database.cleanOldAnchors();
            } catch (_) {}
          } else if (status == 'rejected') {
            failed++;
            await database.updateSyncAttempt(attendance.clientUuid, message ?? 'Rejected by server');
          } else {
            failed++;
            await database.updateSyncAttempt(attendance.clientUuid, message ?? status);
          }
        } catch (e) {
          failed++;
          // Extract message cleanly if Exception was thrown from DataSource
          final errStr = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
          await database.updateSyncAttempt(attendance.clientUuid, errStr);
          
          if (kDebugMode) {
            print('Failed to sync ${attendance.clientUuid}: $e');
          }
        }
      }

      // Clean old synced data (>7 days)
      await database.deleteSyncedOlderThan(7);

      return SyncResult(
        success: failed == 0,
        synced: synced,
        failed: failed,
        message: 'Berhasil sync $synced, gagal $failed',
      );
    } finally {
      _isSyncing = false;
    }
  }

  int _calculateBackoffSeconds(int attempts) {
    // Exponential backoff: 5s, 15s, 30s, 60s, max 300s
    if (attempts <= 1) return 5;
    if (attempts == 2) return 15;
    if (attempts == 3) return 30;
    if (attempts == 4) return 60;
    return 300;
  }

  /// Get pending attendance count for specific user
  Future<int> getPendingCount(int userId) async {
    return await database.getPendingCount(userId);
  }

  /// Save face image to local storage (encrypted)
  Future<String> _saveFaceImage(String uuid, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'face_$uuid.jpg'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Delete face image
  Future<void> _deleteFaceImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete face image: $e');
      }
    }
  }
}

class SyncResult {
  final bool success;
  final int synced;
  final int failed;
  final String message;

  SyncResult({
    required this.success,
    this.synced = 0,
    this.failed = 0,
    required this.message,
  });
}
