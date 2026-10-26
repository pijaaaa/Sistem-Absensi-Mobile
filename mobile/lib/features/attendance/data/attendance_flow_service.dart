import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile/features/attendance/data/attendance_service.dart';
import 'package:mobile/features/attendance/data/repository/attendance_repository.dart';
import 'package:mobile/features/face/data/face_data_source.dart';

/// Service to handle attendance flow: location check -> face verification -> API call.
///
/// Face *detection* + *liveness* run on-device with Google ML Kit (see
/// `MlKitFaceService` / `CameraFaceScreen`). Face *embedding* + *matching*
/// are delegated to the backend `/face/*` endpoints, because OpenCV's `face`
/// module (YuNet/SFace) is unavailable with dartcv4 (it forces
/// `BUILD_opencv_face OFF`).
class AttendanceFlowService {
  final AttendanceLocationService locationService;
  final FaceDataSource faceDataSource;
  final AttendanceRepository repository;

  AttendanceFlowService({
    required this.locationService,
    required this.faceDataSource,
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

  /// Verify a captured face against the employee's stored template via the
  /// backend `/face/verify` endpoint (embedding + matching happen server-side).
  Future<FaceVerificationResult> verifyFace({
    required List<int> imageBytes,
    required double threshold,
  }) async {
    try {
      final result = await faceDataSource.verify(
        photo: Uint8List.fromList(imageBytes),
      );

      final match = result['match'] == true;
      final score = (result['score'] as num?)?.toDouble();

      if (!match) {
        return FaceVerificationResult(
          isValid: false,
          score: score,
          errorMessage:
              'Wajah tidak cocok. Skor: ${(score ?? 0).toStringAsFixed(3)} '
              '(threshold: ${result['threshold'] ?? threshold})',
        );
      }

      return FaceVerificationResult(isValid: true, score: score);
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
    required Uint8List photo,
    required String deviceUid,
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
              photo: photo,
              isBackupDevice: isBackupDevice,
            )
          : await repository.checkOut(
              lat: lat,
              lng: lng,
              faceScoreLocal: faceScore,
              clientUuid: clientUuid,
              deviceUid: deviceUid,
              photo: photo,
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
