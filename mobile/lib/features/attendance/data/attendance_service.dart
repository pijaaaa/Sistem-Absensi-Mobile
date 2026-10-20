import 'package:geolocator/geolocator.dart';

class AttendanceLocationService {
  /// Check location permissions & ensure GPS is enabled
  Future<bool> ensurePermissionAndService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi (GPS) tidak aktif.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak secara permanen. Aktifkan di pengaturan.');
    }

    return true;
  }

  /// Get current position with mock location check
  Future<Position> getCurrentPosition() async {
    await ensurePermissionAndService();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // Check mock location (Android)
    // ignore: deprecated_member_use
    if (position.isMocked) {
      throw Exception('Mock location (Fake GPS) terdeteksi! Mohon matikan aplikasi pemalsu lokasi.');
    }

    return position;
  }

  /// Calculate distance in meters between employee and work location
  double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Check if inside radius (meters)
  bool isInsideRadius({
    required double currentLat,
    required double currentLng,
    required double targetLat,
    required double targetLng,
    required double radiusMeters,
  }) {
    final distance = calculateDistance(
      startLat: currentLat,
      startLng: currentLng,
      endLat: targetLat,
      endLng: targetLng,
    );
    return distance <= radiusMeters;
  }
}
