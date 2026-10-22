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
  final List<List<double>> _embeddings = [];
  bool _isSubmitting = false;

  static const int targetSamples = 3;
  static const String faceModelVersion = 'sface-2021dec+yunet-2023mar';

  Future<void> _captureSample() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin kamera diperlukan untuk mendaftarkan wajah.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Uint8List? captured;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraFaceScreen(
          onFaceCaptured: (bytes, score) {
            captured = bytes;
          },
        ),
      ),
    );

    if (captured == null) return;

    setState(() => _photos.add(captured!));

    try {
      final service = ref.read(faceServiceProvider);
      final embedding = await service.extractEmbedding(captured!);

      if (!mounted) return;
      if (embedding == null || embedding.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wajah tidak terdeteksi. Coba lagi.')),
        );
        return;
      }

      setState(() => _embeddings.add(embedding));
    } catch (e) {
      if (!mounted) return;
      debugPrint('[ENROLL] extractEmbedding error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses wajah: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<bool> _submitEnrollment() async {
    if (_embeddings.isEmpty) return false;

    setState(() => _isSubmitting = true);
    try {
      final dataSource = ref.read(faceDataSourceProvider);
      final response = await dataSource
          .enroll(
            embeddings: _embeddings,
            modelVersion: faceModelVersion,
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return false;

      final count = response['data'] is Map
          ? response['data']['count'] ?? _embeddings.length
          : (response['count'] ?? _embeddings.length);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wajah berhasil didaftarkan ($count sampel).')),
      );

      return true;
    } on DioException catch (e) {
      debugPrint('[ENROLL] DioException: ${e.type} - ${e.response?.data}');
      if (mounted) {
        _showError('${_dioErrorMessage(e)}');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = _embeddings.length >= targetSamples;

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Wajah')),
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
              'Ambil $targetSamples foto wajah dari sudut berbeda untuk pendaftaran akurat.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Sampel terambil: ${_embeddings.length}/$targetSamples',
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
                    child: const Icon(Icons.check_circle, size: 32, color: Colors.green),
                  );
                }),
              ),
            ],
            const Spacer(),
            AppButton(
              text: done ? 'Daftarkan Sekarang' : 'Ambil Foto Wajah',
              icon: done ? Icons.face_retouching_natural : Icons.camera_alt,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting
                  ? null
                  : (done
                      ? () async {
                          final ok = await _submitEnrollment();
                          if (!mounted) return;
                          if (ok) {
                            if (context.canPop()) {
                              context.pop(true);
                            } else {
                              context.go('/home');
                            }
                          }
                        }
                      : _captureSample),
              backgroundColor: done ? AppColors.success : null,
            ),
          ],
        ),
      ),
    );
  }
}
