import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:mobile/features/attendance/presentation/screens/camera_face_screen.dart';
import 'package:mobile/features/attendance/data/attendance_flow_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/auth/presentation/providers/device_providers.dart';

class AttendanceFlowScreen extends ConsumerStatefulWidget {
  final bool isCheckIn;

  const AttendanceFlowScreen({
    super.key,
    required this.isCheckIn,
  });

  @override
  ConsumerState<AttendanceFlowScreen> createState() => _AttendanceFlowScreenState();
}

class _AttendanceFlowScreenState extends ConsumerState<AttendanceFlowScreen> {
  int _currentStep = 0;
  
  // Location step
  bool _isCheckingLocation = false;
  LocationCheckResult? _locationResult;
  
  // Face step
  Uint8List? _capturedImageBytes;
  double? _faceScore;
  
  // Result step
  bool _isSubmitting = false;
  AttendanceResult? _attendanceResult;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    setState(() {
      _isCheckingLocation = true;
    });

    try {
      final flowService = ref.read(attendanceFlowServiceProvider);
      final authState = ref.read(authStateProvider);

      final workLocation = authState.employee?.workLocation;
      final targetLat = workLocation?.lat;
      final targetLng = workLocation?.lng;
      final radius = (workLocation?.radiusM ?? 100).toDouble();

      // Mode 'off' or no coordinates → geofence bypass (backend also skips it)
      if (workLocation?.mode == 'off' || targetLat == null || targetLng == null) {
        final position = await ref.read(attendanceFlowServiceProvider).locationService.getCurrentPosition();
        setState(() {
          _locationResult = LocationCheckResult(
            isValid: true,
            latitude: position.latitude,
            longitude: position.longitude,
            distance: 0,
          );
          _isCheckingLocation = false;
        });
        return;
      }

      final result = await flowService.checkLocation(
        targetLat: targetLat,
        targetLng: targetLng,
        radiusMeters: radius,
      );

      if (mounted) {
        setState(() {
          _locationResult = result;
          _isCheckingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationResult = LocationCheckResult(
            isValid: false,
            errorMessage: e.toString(),
          );
          _isCheckingLocation = false;
        });
      }
    }
  }

  Future<void> _proceedToFaceVerification() async {
    if (_locationResult?.isMockLocation == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mock location (Fake GPS) terdeteksi! Mohon matikan aplikasi pemalsu lokasi.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_locationResult?.isValid != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_locationResult?.errorMessage ?? 'Anda berada di luar area absen'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _currentStep = 1;
    });
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
         builder: (context) => CameraFaceScreen(
           onFaceCaptured: (bytes) {
             setState(() {
               _capturedImageBytes = bytes;
               // Face liveness was enforced on-device (head-turn challenges)
               // in CameraFaceScreen, so a captured photo = verified liveness.
               _faceScore = 1.0;
             });
           },
         ),
      ),
    );

    if (result == true && _capturedImageBytes != null) {
      _submitAttendance();
    }
  }

  Future<void> _submitAttendance() async {
    if (_locationResult == null || _capturedImageBytes == null) return;

    setState(() {
      _isSubmitting = true;
      _currentStep = 2;
    });

    try {
      // Check connectivity
      final offlineService = ref.read(offlineAttendanceServiceProvider);
      final isOnline = await offlineService.isOnline();

      if (isOnline) {
        // Online: submit langsung ke API
        final flowService = ref.read(attendanceFlowServiceProvider);
        final deviceService = ref.read(deviceServiceProvider);
        final deviceUid = await deviceService.getDeviceUid();

        final result = await flowService.submitAttendance(
          isCheckIn: widget.isCheckIn,
          lat: _locationResult!.latitude!,
          lng: _locationResult!.longitude!,
          faceScore: _faceScore ?? 0.0,
          photo: _capturedImageBytes!,
          deviceUid: deviceUid,
        );

        if (mounted) {
          setState(() {
            _attendanceResult = result;
            _isSubmitting = false;
          });
        }
      } else {
        // Offline: save ke database lokal
        await offlineService.saveOfflineAttendance(
          isCheckIn: widget.isCheckIn,
          lat: _locationResult!.latitude!,
          lng: _locationResult!.longitude!,
          faceScore: _faceScore ?? 0.0,
          faceImageBytes: _capturedImageBytes,
        );

        if (mounted) {
          setState(() {
            _attendanceResult = AttendanceResult(
              success: true,
              data: {
                'message': 'Absensi tersimpan offline',
                'time': DateTime.now().toString().substring(11, 16),
                'status': 'Akan disinkronkan otomatis',
                'is_offline': true,
              },
            );
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
            _attendanceResult = AttendanceResult(
              success: false,
              errorMessage: e.toString().replaceAll('Exception: ', ''),
            );
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCheckIn ? 'Absen Masuk' : 'Absen Pulang'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Stepper Progress
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepIndicator(0, 'Lokasi'),
                _buildStepLine(0),
                _buildStepIndicator(1, 'Wajah'),
                _buildStepLine(1),
                _buildStepIndicator(2, 'Selesai'),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildLocationStep(),
                _buildFaceStep(),
                _buildResultStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final theme = Theme.of(context);

    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          child: isActive && _currentStep > step
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text(
                  '${step + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
             color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int beforeStep) {
    final isActive = _currentStep > beforeStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 28),
        color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildLocationStep() {
    final theme = Theme.of(context);

    if (_isCheckingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memeriksa lokasi Anda...'),
          ],
        ),
      );
    }

    final isMockLocation = _locationResult?.isMockLocation == true;
    final isValid = _locationResult?.isValid == true;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            isMockLocation
                ? Icons.warning
                : isValid
                    ? Icons.check_circle
                    : Icons.location_off,
            size: 80,
            color: isMockLocation
                ? AppColors.pending
                : isValid
                    ? AppColors.success
                    : AppColors.error,
          ),
          const SizedBox(height: 24),
          Text(
            isMockLocation
                ? 'Mock Location Terdeteksi'
                : isValid
                    ? 'Lokasi Valid'
                    : 'Di Luar Area',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isMockLocation
                  ? AppColors.pending
                  : isValid
                      ? AppColors.success
                      : AppColors.error,
            ),
          ),
          const SizedBox(height: 12),
          if (isMockLocation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Aplikasi Fake GPS terdeteksi! Mohon matikan aplikasi pemalsu lokasi untuk melanjutkan absensi.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          else if (_locationResult?.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _locationResult!.errorMessage!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          else if (isValid)
            Text(
              'Anda berada di dalam area kerja',
              style: theme.textTheme.bodyMedium,
            ),
          if (_locationResult?.distance != null) ...[
            const SizedBox(height: 16),
            Text(
              'Jarak: ${_locationResult!.distance!.toStringAsFixed(0)} m',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const Spacer(),
          if (isMockLocation)
            AppButton(
              text: 'Coba Lagi',
              onPressed: _checkLocation,
              outline: true,
            )
          else if (isValid)
            AppButton(
              text: 'Lanjutkan ke Verifikasi Wajah',
              onPressed: _proceedToFaceVerification,
            )
          else
            AppButton(
              text: 'Coba Lagi',
              onPressed: _checkLocation,
              outline: true,
            ),
        ],
      ),
    );
  }

  Widget _buildFaceStep() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.face,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Verifikasi Wajah',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pastikan wajah Anda terlihat jelas dan berada dalam kondisi cahaya yang cukup',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          AppButton(
            text: 'Buka Kamera',
            onPressed: _openCamera,
            icon: Icons.camera_alt,
          ),
        ],
      ),
    );
  }

  Widget _buildResultStep() {
    final theme = Theme.of(context);

    if (_isSubmitting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memproses absensi...'),
          ],
        ),
      );
    }

    final success = _attendanceResult?.success == true;
    final data = _attendanceResult?.data;
    final isOffline = data?['is_offline'] == true;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            success ? (isOffline ? Icons.cloud_off : Icons.check_circle) : Icons.error,
            size: 100,
            color: success ? (isOffline ? AppColors.pending : AppColors.success) : AppColors.error,
          ),
          const SizedBox(height: 24),
          Text(
            success 
                ? (isOffline ? 'Tersimpan Offline' : 'Absensi Berhasil!')
                : 'Absensi Gagal',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: success ? (isOffline ? AppColors.pending : AppColors.success) : AppColors.error,
            ),
          ),
          const SizedBox(height: 12),
          if (success && data != null) ...[
            Text(
              data['message'] ?? 'Absensi ${widget.isCheckIn ? "masuk" : "pulang"} berhasil dicatat',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (isOffline) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pending.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.pending),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.pending, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Data akan disinkronkan otomatis saat terhubung ke internet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.pending,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (data['time'] != null)
              _buildInfoRow('Waktu', data['time']),
            if (data['status'] != null && !isOffline)
              _buildInfoRow('Status', data['status']),
          ] else if (_attendanceResult?.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _attendanceResult!.errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          const Spacer(),
          if (!success && _attendanceResult?.errorMessage != null &&
              (_attendanceResult!.errorMessage!.toLowerCase().contains('wajah') ||
                  _attendanceResult!.errorMessage!.toLowerCase().contains('face')))
            AppButton(
              text: 'Daftar Wajah',
              onPressed: () {
                context.go('/enrollment');
              },
              icon: Icons.face_retouching_natural,
              outline: true,
            ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Selesai',
            onPressed: () {
              Navigator.pop(context, success);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
