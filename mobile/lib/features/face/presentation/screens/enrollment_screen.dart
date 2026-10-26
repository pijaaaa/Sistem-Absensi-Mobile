import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/features/attendance/presentation/screens/camera_face_screen.dart';
import 'package:mobile/features/face/presentation/providers/face_providers.dart';

class EnrollmentScreen extends ConsumerStatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  final List<Uint8List> _photos = [];
  bool _isSubmitting = false;
  bool _hasTemplateDownloaded = false;

  static const int targetSamples = 3;
  static const String faceModelVersion = 'sface-2021dec+yunet-2023mar';

  @override
  void initState() {
    super.initState();
    _downloadExistingTemplate();
  }

  Future<void> _downloadExistingTemplate() async {
    try {
      final dataSource = ref.read(faceDataSourceProvider);
      final template = await dataSource.downloadTemplate();
      if (template != null) {
        setState(() {
          _hasTemplateDownloaded = true;
        });
      }
    } catch (e) {
      debugPrint('[ENROLL] downloadTemplate error: $e');
    }
  }

  Future<void> _startEnrollmentWithLiveness() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin kamera diperlukan untuk mendaftarkan wajah.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Uint8List? captured;

    if (!mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraFaceScreen(
          onFaceCaptured: (bytes) {
            captured = bytes;
          },
          requireLiveness: true,
          isEnrollment: true,
        ),
      ),
    );

    if (captured == null) return;

    setState(() => _photos.add(captured!));
  }

  Future<bool> _submitEnrollment() async {
    if (_photos.isEmpty) return false;

    setState(() => _isSubmitting = true);
    try {
      final dataSource = ref.read(faceDataSourceProvider);
      final response = await dataSource
          .enroll(
            photos: _photos,
            modelVersion: faceModelVersion,
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return false;

      final count = response['data'] is Map
          ? response['data']['count'] ?? _photos.length
          : (response['count'] ?? _photos.length);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wajah berhasil didaftarkan ($count sampel).')),
      );

      return true;
    } on DioException catch (e) {
      debugPrint('[ENROLL] DioException: ${e.type} - ${e.response?.data}');
      if (mounted) {
        _showError(_dioErrorMessage(e));
      }
      return false;
    } catch (e) {
      debugPrint('[ENROLL] ${e.toString()}');
      if (mounted) {
        _showError(e.toString());
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  String _dioErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['message'] != null) return data['message'].toString();
      if (data['errors'] != null) {
        return (data['errors'] as Map).values.first.toString();
      }
    }
    return 'Gagal (HTTP ${e.response?.statusCode ?? e.type})';
  }

  Future<void> _showBiometricConsent() async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Persetujuan Data Biometrik'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Aplikasi ini akan mengumpulkan data wajah (embedding) untuk keperluan absensi. Data ini:',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 8),
              Text('• Disimpan terenkripsi di server', style: TextStyle(height: 1.5)),
              Text('• Digunakan hanya untuk verifikasi absensi', style: TextStyle(height: 1.5)),
              Text('• Tidak pernah disimpan sebagai foto permanen', style: TextStyle(height: 1.5)),
              Text('• Dapat dihapus dengan menghubungi admin', style: TextStyle(height: 1.5)),
              SizedBox(height: 12),
              Text('Dengan menyetujui, Anda setuju data biometrik Anda akan digunakan untuk absensi.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tolak'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Setuju & Lanjut'),
          ),
        ],
      ),
    );

    if (accepted != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran wajah dibatalkan.'),
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = _photos.length >= targetSamples;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Navigate back to home instead of exiting app
        context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Wajah'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          actions: [
            if (_hasTemplateDownloaded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.download,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
          ],
        ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.face_retouching_natural,
                size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Pendaftaran Wajah',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ambil $targetSamples foto wajah dari sudut berbeda dengan liveness challenge.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Sampel terambil: ${_photos.length}/$targetSamples',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_photos.length, (i) {
                  return Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle,
                        size: 32, color: Colors.green),
                  );
                }),
              ),
            ],
            const Spacer(),
            AppButton(
              text: done
                  ? 'Daftarkan dengan Liveness'
                  : 'Ambil Sampel dengan Liveness',
              icon: done ? Icons.face_retouching_natural : Icons.camera_alt,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting
                  ? null
                  : (done
                      ? () async {
                          final goRouter = GoRouter.of(context);
                          await _showBiometricConsent();
                          final ok = await _submitEnrollment();
                          if (!mounted) return;
                          if (ok) {
                            goRouter.go('/home');
                          }
                        }
                      : _startEnrollmentWithLiveness),
              backgroundColor: done ? AppColors.success : null,
            ),
           ],
          ),
        ),
      ),
    );
  }
}
