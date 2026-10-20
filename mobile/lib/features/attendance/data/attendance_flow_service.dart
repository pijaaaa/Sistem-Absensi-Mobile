import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile/features/attendance/data/attendance_service.dart';
import 'package:mobile/features/attendance/data/repository/attendance_repository.dart';
import 'package:mobile/features/face/data/face_service.dart';

/// Service to handle attendance flow: location check -> face verification -> API call
class AttendanceFlowService {
  final AttendanceLocationService locationService;
  final BaseFaceService faceService;
  final AttendanceRepository repository;

  AttendanceFlowService({
    required this.locationService,
    required this.faceService,
    required this.repository,
  });

  /// Check if mock location is enabled
  Future<bool> isMockLocationEnabled() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return position.isMocked;
    } catch (e) {
      return false;
    }
  }

  /// Get current location with validation
  Future<LocationCheckResult> checkLocation({
    required double targetLat,
    required double targetLng,
    required double radiusMeters,
  }) async {
    try {
      // Check mock location first
      if (await isMockLocationEnabled()) {
        return LocationCheckResult(
          isValid: false,
          errorMessage: 'Mock location (Fake GPS) terdeteksi! Mohon matikan aplikasi pemalsu lokasi.',
          isMockLocation: true,
        );
      }

      final position = await locationService.getCurrentPosition();
      
      final distance = locationService.calculateDistance(
        startLat: position.latitude,
        startLng: position.longitude,
        endLat: targetLat,
        endLng: targetLng,
      );

      final isInside = distance <= radiusMeters;

      return LocationCheckResult(
        isValid: isInside,
        latitude: position.latitude,
        longitude: position.longitude,
        distance: distance,
        errorMessage: isInside ? null : 'Anda berada di luar area absen (${distance.toStringAsFixed(0)} m dari lokasi).',
      );
    } catch (e) {
      return LocationCheckResult(
        isValid: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Capture and verify face
  Future<FaceVerificationResult> verifyFace({
    required List<int> imageBytes,
    required List<double> storedEmbedding,
    required double threshold,
  }) async {
    try {
      // Extract embedding from captured image
      final liveEmbedding = await faceService.extractEmbedding(imageBytes);
      
      if (liveEmbedding == null) {
        return FaceVerificationResult(
          isValid: false,
          errorMessage: 'Wajah tidak terdeteksi. Pastikan wajah terlihat jelas.',
        );
      }

      // Match with stored embedding
      final score = faceService.match(storedEmbedding, liveEmbedding);
      
      final isValid = score >= threshold;

      return FaceVerificationResult(
        isValid: isValid,
        score: score,
        errorMessage: isValid ? null : 'Wajah tidak cocok. Skor: ${(score * 100).toStringAsFixed(1)}%',
      );
    } catch (e) {
      return FaceVerificationResult(
        isValid: false,
        errorMessage: 'Error verifikasi wajah: ${e.toString()}',
      );
    }
  }

  /// Submit attendance (check-in or check-out)
  Future<AttendanceResult> submitAttendance({
    required bool isCheckIn,
    required double lat,
    required double lng,
    required double faceScore,
    String? deviceUid,
    bool isBackupDevice = false,
  }) async {
    try {
      final clientUuid = const Uuid().v4();

      final response = isCheckIn
          ? await repository.checkIn(
              lat: lat,
              lng: lng,
              faceScoreLocal: faceScore,
              clientUuid: clientUuid,
              deviceUid: deviceUid,
              isBackupDevice: isBackupDevice,
            )
          : await repository.checkOut(
              lat: lat,
              lng: lng,
              faceScoreLocal: faceScore,
              clientUuid: clientUuid,
              deviceUid: deviceUid,
            );

      return AttendanceResult(
        success: true,
        data: response,
      );
    } catch (e) {
      return AttendanceResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}

/// Result models
class LocationCheckResult {
  final bool isValid;
  final double? latitude;
  final double? longitude;
  final double? distance;
  final String? errorMessage;
  final bool isMockLocation;

  LocationCheckResult({
    required this.isValid,
    this.latitude,
    this.longitude,
    this.distance,
    this.errorMessage,
    this.isMockLocation = false,
  });
}

class FaceVerificationResult {
  final bool isValid;
  final double? score;
  final String? errorMessage;

  FaceVerificationResult({
    required this.isValid,
    this.score,
    this.errorMessage,
  });
}

class AttendanceResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  AttendanceResult({
    required this.success,
    this.data,
    this.errorMessage,
  });
}
