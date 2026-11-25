import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
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
  int _retryAttempts = 0;
  String? _serverMessage;
  String? _decisionStatus; // 'pass', 'retry', 'review', 'reject'

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

      // Mode 'off'/'polygon' or no coordinates → skip circle pre-check (backend validates polygon)
      if (workLocation?.mode == 'off' ||
          workLocation?.mode == 'polygon' ||
          targetLat == null ||
          targetLng == null) {
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
           requireLiveness: true,
           isEnrollment: false,
           onFaceCaptured: (bytes) {
             setState(() {
               _capturedImageBytes = bytes;
               // W3 liveness passed via camera challenges & quality gate
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
      final offlineService = ref.read(offlineAttendanceServiceProvider);
      final isOnline = await offlineService.isOnline();

      if (isOnline) {
        final flowService = ref.read(attendanceFlowServiceProvider);
        final deviceService = ref.read(deviceServiceProvider);
        final deviceUid = await deviceService.getDeviceUid();

        final result = await flowService.submitAttendance(
          isCheckIn: widget.isCheckIn,
          lat: _locationResult!.latitude!,
          lng: _locationResult!.longitude!,
          faceScore: _faceScore ?? 1.0,
          photo: _capturedImageBytes!,
          deviceUid: deviceUid,
        );

        if (mounted) {
          final responseData = result.data;
          final decision = responseData?['decision'] ?? responseData?['status'] ?? (result.success ? 'pass' : 'reject');
          final message = responseData?['message'] ?? responseData?['error'] ?? result.errorMessage;

          setState(() {
            _decisionStatus = decision;
            _serverMessage = message;
            _attendanceResult = result;
            _isSubmitting = false;
            if (decision == 'retry' || decision == 'review') {
              _retryAttempts++;
            }
          });
        }
      } else {
        // Offline Fallback (W5 Requirement 4): record offline queue item with encrypted crop & local score
        final authState = ref.read(authStateProvider);
        final userId = authState.user?.id ?? authState.employee?.id ?? 0;
        await offlineService.saveOfflineAttendance(
          userId: userId,
          isCheckIn: widget.isCheckIn,
          lat: _locationResult!.latitude!,
          lng: _locationResult!.longitude!,
          faceScoreReal: _faceScore ?? 1.0,
          faceImageBytes: _capturedImageBytes,
        );

        if (mounted) {
          setState(() {
            _decisionStatus = 'pass';
            _attendanceResult = AttendanceResult(
              success: true,
              data: {
                'message': 'Absensi tersimpan offline (terenkripsi)',
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
          _decisionStatus = 'reject';
          _serverMessage = e.toString().replaceAll('Exception: ', '');
          _attendanceResult = AttendanceResult(
            success: false,
            errorMessage: _serverMessage,
          );
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFlowHeader(),
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

  Widget _buildFlowHeader() {
    final theme = Theme.of(context);
    const labels = ['Lokasi', 'Wajah', 'Hasil'];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusXL),
          bottomRight: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingSM,
            AppTheme.spacingSM,
            AppTheme.spacingLG,
            AppTheme.spacingLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Kembali',
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isCheckIn ? 'Absen Masuk' : 'Absen Pulang',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Langkah ${_currentStep + 1} dari 3 · ${labels[_currentStep]}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Row(
                children: [
                  _buildStepIndicator(0, labels[0]),
                  _buildStepLine(0),
                  _buildStepIndicator(1, labels[1]),
                  _buildStepLine(1),
                  _buildStepIndicator(2, labels[2]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isDone = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: AppColors.primary, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? AppColors.primary : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
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
        margin: const EdgeInsets.only(bottom: 24, left: 6, right: 6),
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.25),
      ),
    );
  }

  Widget _buildLocationStep() {
    final theme = Theme.of(context);
    final workLocation = ref.watch(authStateProvider).employee?.workLocation;
    final radius = workLocation?.radiusM ?? 100;

    if (_isCheckingLocation) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Memeriksa lokasi Anda...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final isMockLocation = _locationResult?.isMockLocation == true;
    final isValid = _locationResult?.isValid == true;
    final distance = _locationResult?.distance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _LocationIllustration(
                  valid: isValid && !isMockLocation,
                  radius: radius,
                ),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isMockLocation
                                    ? Icons.warning_amber_rounded
                                    : isValid
                                        ? Icons.check_circle
                                        : Icons.location_off,
                                size: 18,
                                color: isMockLocation
                                    ? AppColors.pending
                                    : isValid
                                        ? AppColors.success
                                        : AppColors.error,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isMockLocation
                                    ? 'Mock Location'
                                    : isValid
                                        ? 'Lokasi valid'
                                        : 'Di luar radius',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isMockLocation
                                      ? AppColors.pending
                                      : isValid
                                          ? AppColors.success
                                          : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Radius $radius m',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                      Text(
                        workLocation?.name ?? 'Kantor',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${distance.toStringAsFixed(0)} m',
                                style: theme.textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              TextSpan(
                                text: '  dari batas $radius m',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingMD),
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoBlock(
                              label: 'Jam sekarang',
                              value:
                                  '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB',
                            ),
                          ),
                          Expanded(
                            child: _InfoBlock(
                              label: 'Jam kerja',
                              value: '08:00–17:00',
                            ),
                          ),
                        ],
                      ),
                      if (isMockLocation) ...[
                        const SizedBox(height: AppTheme.spacingMD),
                        Text(
                          'Aplikasi Fake GPS terdeteksi. Matikan aplikasi pemalsu lokasi untuk melanjutkan.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.pending,
                          ),
                        ),
                      ] else if (!isValid &&
                          _locationResult?.errorMessage != null) ...[
                        const SizedBox(height: AppTheme.spacingMD),
                        Text(
                          _locationResult!.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          if (isMockLocation || !isValid)
            AppButton(
              text: 'Coba Lagi',
              onPressed: _checkLocation,
              outline: true,
              icon: Icons.refresh,
            )
          else
            AppButton(
              text: 'Lanjut ke Verifikasi Wajah',
              onPressed: _proceedToFaceVerification,
              icon: Icons.arrow_forward,
            ),
        ],
      ),
    );
  }

  Widget _buildFaceStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spacingMD),
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face_retouching_natural,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),
                Text(
                  'Verifikasi Wajah',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pastikan wajah Anda terlihat jelas dengan pencahayaan yang cukup.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLG),
                _ChecklistItem(text: 'Pencahayaan cukup'),
                _ChecklistItem(text: 'Lepas masker atau penutup wajah'),
                _ChecklistItem(text: 'Hadapkan wajah ke kamera'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Memproses absensi & keputusan server...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final bool isOffline = _attendanceResult?.data?['is_offline'] == true;
    final String decision = isOffline ? 'pass' : (_decisionStatus ?? (_attendanceResult?.success == true ? 'pass' : 'reject'));

    final bool isPass = decision == 'pass' || decision == 'synced' || decision == 'created';
    final bool isRetryOrReview = decision == 'retry' || decision == 'review';
    final bool isReject = decision == 'reject';

    IconData iconData = Icons.check_circle;
    Color iconColor = AppColors.success;
    String titleText = 'Absensi Berhasil';

    if (isOffline) {
      iconData = Icons.cloud_off;
      iconColor = AppColors.pending;
      titleText = 'Tersimpan Offline';
    } else if (isRetryOrReview) {
      iconData = Icons.warning_amber_rounded;
      iconColor = AppColors.pending;
      titleText = 'Perlu Review / Ulang';
    } else if (isReject || !_attendanceResult!.success) {
      iconData = Icons.block;
      iconColor = AppColors.error;
      titleText = 'Absensi Ditolak';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spacingMD),
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, size: 44, color: iconColor),
                ),
                const SizedBox(height: AppTheme.spacingMD),
                Text(
                  titleText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (isRetryOrReview) ...[
                  Text(
                    _serverMessage ?? 'Kualitas wajah kurang atau ragu-ragu. Sisa percobaan: ${3 - _retryAttempts}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.pending),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Percobaan ke-$_retryAttempts dari 3',
                    style: theme.textTheme.bodySmall,
                  ),
                ] else if (isReject) ...[
                  Text(
                    _serverMessage ?? 'Wajah tidak cocok atau verifikasi liveness gagal. Akses absen dikunci sementara.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    _serverMessage ?? _attendanceResult?.data?['message'] ?? 'Absensi ${widget.isCheckIn ? "masuk" : "pulang"} berhasil dicatat',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (isOffline) ...[
                    const SizedBox(height: AppTheme.spacingMD),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.pending.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        border: Border.all(color: AppColors.pending.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.pending, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Crop wajah terenkripsi & skor lokal tersimpan offline. Disinkron otomatis saat online.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.pending,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                if (_attendanceResult?.data?['time'] != null) ...[
                  const SizedBox(height: AppTheme.spacingMD),
                  Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  _buildInfoRow('Waktu', _attendanceResult!.data!['time']),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          if (isRetryOrReview && _retryAttempts < 3) ...[
            AppButton(
              text: 'Coba Ambil Foto Ulang',
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                  _capturedImageBytes = null;
                });
                _openCamera();
              },
              icon: Icons.camera_alt,
            ),
            const SizedBox(height: 12),
          ] else if (isReject) ...[
            AppButton(
              text: 'Daftar Ulang Wajah',
              onPressed: () {
                context.go('/enrollment');
              },
              icon: Icons.face_retouching_natural,
              outline: true,
            ),
            const SizedBox(height: 12),
          ],
          AppButton(
            text: 'Kembali ke Beranda',
            onPressed: () {
              Navigator.pop(context, isPass || isOffline);
            },
            icon: Icons.home_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LocationIllustration extends StatelessWidget {
  final bool valid;
  final int radius;

  const _LocationIllustration({required this.valid, required this.radius});

  @override
  Widget build(BuildContext context) {
    final color = valid ? AppColors.primary : AppColors.error;

    return Container(
      height: 168,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primarySoft,
            AppColors.primarySoft.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusLG),
          topRight: Radius.circular(AppTheme.radiusLG),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 22,
            ),
          ),
          Positioned(
            top: 20,
            right: 24,
            child: Text(
              'Radius $radius m',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;

  const _ChecklistItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 14,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
