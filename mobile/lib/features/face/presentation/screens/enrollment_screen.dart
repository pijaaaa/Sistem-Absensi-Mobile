import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/empty_state.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/features/face/presentation/providers/face_providers.dart';
import 'package:mobile/features/face/data/face_service.dart';

class EnrollmentScreen extends ConsumerStatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  static const int totalSamples = 5;
  final List<String> _challenges = [
    'Aktifkan kamera dan pastikan wajah terlihat jelas',
    'Kedipkan mata Anda',
    'Tengok ke kiri',
    'Tengok ke kanan',
    'Kedipkan mata lagi',
  ];

  int _currentChallenge = 0;
  bool _isCapturing = false;
  bool _faceServiceReady = false;
  bool _showConsent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeFaceService();
  }

  Future<void> _initializeFaceService() async {
    final service = ref.read(faceServiceProvider);
    final result = await service.initialize();
    setState(() => _faceServiceReady = result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!kIsWeb && !_faceServiceReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daftar Wajah')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Mempersiapkan layanan wajah...', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    if (_showConsent) {
      return _buildConsentScreen(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Wajah'),
      ),
      body: _faceServiceReady
          ? _buildEnrollmentBody(context)
          : _buildWebFallbackBody(context),
    );
  }

  Widget _buildEnrollmentBody(BuildContext context) {
    final state = ref.watch(faceEnrollmentProvider);
    final theme = Theme.of(context);

    if (!state.isInEnrollment) {
      // Initial state - show start button
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.face_retouching_natural, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Daftar Wajah',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Anda perlu mendaftarkan wajah untuk dapat absen.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Diperlukan $totalSamples foto wajah dari sudut berbeda.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Mulai Pendaftaran',
              onPressed: () {
                setState(() => _showConsent = true);
                ref.read(faceEnrollmentProvider.notifier).startEnrollment();
              },
            ),
            const SizedBox(height: 24),
            const Text('File logo disediakan manual di assets/images/'),
          ],
        ),
      );
    }

    // Enrollment in progress
    return _buildLivenessCapture(context, state);
  }

  Widget _buildLivenessCapture(BuildContext context, FaceEnrollmentState state) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Ambil ${state.samplesTaken}/$totalSamples foto',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: state.samplesTaken / totalSamples,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: theme.colorScheme.primary,
                minHeight: 6,
              ),
            ],
          ),
        ),

        // Liveness challenge
        if (!state.livenessPassed) ...[
          const SizedBox(height: 12),
          Text(
            state.livenessChallenge.isNotEmpty
                ? state.livenessChallenge
                : 'Siapkan wajah Anda',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ikuti instruksi di layar',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],

        // Face preview / camera preview
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: state.livenessPassed ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.face,
                    size: 64,
                    color: Colors.grey,
                  ),
                  if (state.livenessPassed)
                    const Icon(Icons.check_circle, size: 48, color: Colors.green),
                ],
              ),
            ),
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (_errorMessage != null)
                Text(_errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
              if (state.livenessPassed)
                AppButton(
                  text: _isCapturing ? 'Mengambil foto...' : 'Ambil Foto',
                  onPressed: _isCapturing ? null : () async {
                      await _captureAndProcess();
                    },
                  icon: Icons.camera_alt,
                ),
              if (_faceServiceReady && !state.livenessPassed)
                TextButton.icon(
                  onPressed: _startLiveness,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Uji Coba Liveness'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _startLiveness() {
    setState(() {
      _currentChallenge = 0;
      _showConsent = false;
      ref.read(faceEnrollmentProvider.notifier).setLivenessChallenge(_challenges[0]);
    });
  }

  Future<void> _captureAndProcess() async {
    setState(() => _isCapturing = true);
    final picker = ImagePicker();

    try {
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      final bytes = await image.readAsBytes();

      // Extract embedding (will use real opencv_dart on device)
      final service = ref.read(faceServiceProvider);
      final embedding = await service.extractEmbedding(bytes);

      if (embedding == null || embedding.isEmpty) {
        setState(() => _errorMessage = 'Wajah tidak terdeteksi. Coba lagi.');
        return;
      }

      ref.read(faceEnrollmentProvider.notifier).addSample();

      final state = ref.read(faceEnrollmentProvider);

      if (state.samplesTaken < totalSamples) {
        // Next sample
        _startNextLiveness();
      } else {
        // Completion
        ref.read(faceEnrollmentProvider.notifier).completeEnrollment();
        _completeEnrollment();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().contains('multiple_faces')
          ? 'Lebih dari satu wajah terdeteksi. Pastikan hanya Anda.'
          : 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _startNextLiveness() {
    setState(() {
      _currentChallenge = (_currentChallenge + 1) % _challenges.length;
      ref.read(faceEnrollmentProvider.notifier).setLivenessChallenge(_challenges[_currentChallenge]);
    });
    // Reset previous liveness
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(faceEnrollmentProvider.notifier).completeLiveness();
    });
  }

  void _completeEnrollment() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 56, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Pendaftaran Selesai!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Anda sekarang dapat melakukan absen.'),
            const SizedBox(height: 24),
            AppButton(
              text: 'Kembali ke Beranda',
              onPressed: () => Navigator.pop(context),
              backgroundColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // Web fallback (since opencv_dart doesn't work on web)
  Widget _buildWebFallbackBody(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Pendaftaran Wajah',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Fitur ini tersedia di perangkat Android.\nSilakan jalankan di HP untuk melakukan pendaftaran wajah.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Hubungi IT Support',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildConsentScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Data Biometrik'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Persetujuan Penggunaan Data Biometrik',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'PT Bumi Siak Pusako akan mengumpulkan data wajah (embedding vektor) untuk:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Verifikasi identitas saat absen'),
            _buildBulletPoint('Prevention kecurangan absen'),
            _buildBulletPoint('One-time enrollment, verifikasi on-device'),
            const SizedBox(height: 16),
            Text(
              'Data biometrik disimpan terenkripsi dan tidak akan dijual atau digunakan untuk keperluan lain.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Saya Setuju',
              onPressed: () {
                setState(() => _showConsent = false);
              },
              backgroundColor: Colors.green,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
