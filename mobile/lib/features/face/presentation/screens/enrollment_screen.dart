import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  bool _isSubmitting = false;
  bool _hasTemplateDownloaded = false;

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

  Future<void> _startEnrollment() async {
    // 1. Biometric consent screen prior to camera open
    final consented = await _showBiometricConsent();
    if (consented != true) return;

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

    // 2. Stepper flow integrating W3 liveness challenges (front, left, right poses in single CameraFaceScreen session)
    List<Uint8List> capturedSamples = [];

    if (!mounted) return;
    
    // Single CameraFaceScreen session with requireLiveness: true executes front -> left -> right challenges & captures photos
    bool? livenessDone = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraFaceScreen(
          onFaceCaptured: (bytes) {
            capturedSamples.add(bytes);
          },
          requireLiveness: true,
          isEnrollment: true,
        ),
      ),
    );

    if (livenessDone != true || capturedSamples.isEmpty) return;

    if (!mounted) return;
    final goRouter = GoRouter.of(context);
    
    // 3. Multi-pose sample capture and submission to enrollment API
    // 4. Secure local template download & encryption
    final ok = await _submitEnrollmentAndSecureTemplate(capturedSamples);
    if (!mounted) return;
    if (ok) {
      goRouter.go('/home');
    }
  }

  Future<bool> _submitEnrollmentAndSecureTemplate(List<Uint8List> photos) async {
    setState(() => _isSubmitting = true);
    try {
      final dataSource = ref.read(faceDataSourceProvider);
      final response = await dataSource
          .enroll(
            photos: photos,
            modelVersion: faceModelVersion,
          )
          .timeout(const Duration(seconds: 45));

      if (!mounted) return false;

      final count = response['data'] is Map
          ? response['data']['count'] ?? photos.length
          : (response['count'] ?? photos.length);

      // Secure local template download & encryption
      final templateEmbedding = await dataSource.downloadTemplate();
      if (templateEmbedding != null) {
        const secureStorage = FlutterSecureStorage();
        final jsonString = jsonEncode(templateEmbedding);
        // Encrypt & store locally securely
        await secureStorage.write(key: 'secure_face_template', value: jsonString);
        setState(() => _hasTemplateDownloaded = true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wajah berhasil didaftarkan ($count sampel) & template terenkripsi lokal.')),
        );
      }

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

  Future<void> _deleteFace(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Text('Hapus Template Wajah'),
          ],
        ),
        content: const Text(
          'Anda yakin ingin menghapus template wajah? '
          'Anda perlu mendaftarkan ulang saat ingin absen berbasis wajah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (!confirmed!) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);
    try {
      final dataSource = ref.read(faceDataSourceProvider);
      await dataSource.deleteFace();
      setState(() {
        _hasTemplateDownloaded = false;
      });
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Template wajah berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool?> _showBiometricConsent() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Persetujuan Penggunaan Data Biometrik'),
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
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
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
                'Satu sesi liveness (toleh kiri-kanan) lalu foto terambil otomatis.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_hasTemplateDownloaded)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Template wajah sudah terdaftar. Daftar ulang untuk memperbarui.',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              AppButton(
                text: 'Daftar Wajah dengan Liveness',
                icon: Icons.face_retouching_natural,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _startEnrollment,
              ),
              if (_hasTemplateDownloaded) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _isSubmitting ? null : () => _deleteFace(context, ref),
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  label: Text(
                    'Hapus Wajah',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
