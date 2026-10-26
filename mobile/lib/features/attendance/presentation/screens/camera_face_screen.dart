import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/face/presentation/providers/face_providers.dart';

enum LivenessChallengeType { turnLeft, turnRight }

class LivenessChallenge {
  final LivenessChallengeType type;
  final String instruction;
  final String semanticLabel;

  LivenessChallenge({
    required this.type,
    required this.instruction,
    required this.semanticLabel,
  });
}

class CameraFaceScreen extends ConsumerStatefulWidget {
  final Function(Uint8List imageBytes) onFaceCaptured;
  final bool requireLiveness;
  final bool isEnrollment;

  const CameraFaceScreen({
    super.key,
    required this.onFaceCaptured,
    this.requireLiveness = true,
    this.isEnrollment = false,
  });

  @override
  ConsumerState<CameraFaceScreen> createState() => _CameraFaceScreenState();
}

class _CameraFaceScreenState extends ConsumerState<CameraFaceScreen> {
  CameraController? _controller;
  bool _cameraReady = false;
  bool _faceServiceReady = false;

  bool _faceDetected = false;
  bool _livenessActive = false;
  bool _livenessDone = false;
  int _currentChallengeIndex = 0;
  bool _challengeCompleted = false;
  double _progress = 0.0;
  bool _capturing = false;

  // Polling / analysis state
  Timer? _pollTimer;
  Timer? _showSkipTimer;
  bool _analyzing = false;
  int _challengeAttempts = 0;
  bool _showSkip = false;
  // Sign of the head turn detected in the first challenge ('left' or 'right').
  // The second challenge requires the opposite turn — this makes liveness
  // robust to front-camera mirror conventions (sign of yaw flips when mirrored).
  String? _firstTurnDirection;

  static const int _maxAttemptsPerChallenge = 10;
  static const _pollInterval = Duration(milliseconds: 700);
  static const double _yawThreshold = 12.0; // degrees off-center

  late final List<LivenessChallenge> _challenges;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _challenges = _buildChallenges();

    _initialize();
  }

  List<LivenessChallenge> _buildChallenges() {
    // Blink challenge removed per requirement — only head turns remain.
    return [
      LivenessChallenge(
        type: LivenessChallengeType.turnLeft,
        instruction: 'Putar kepala ke kiri',
        semanticLabel: 'Tantangan putar kepala ke kiri',
      ),
      LivenessChallenge(
        type: LivenessChallengeType.turnRight,
        instruction: 'Putar kepala ke kanan',
        semanticLabel: 'Tantangan putar kepala ke kanan',
      ),
    ];
  }

  Future<void> _initialize() async {
    await _initFaceService();

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final imageFormat = Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.jpeg;

      // Low resolution keeps ML Kit analysis fast on older devices.
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: imageFormat,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() => _cameraReady = true);

      if (_faceServiceReady) {
        if (widget.requireLiveness) {
          _startLiveness();
        }
        _startPolling();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error kamera: ${e.toString()}')),
      );
    }
  }

  Future<void> _initFaceService() async {
    final faceService = ref.read(faceServiceProvider);
    try {
      final ok = await faceService.initialize();
      if (!mounted) return;
      setState(() => _faceServiceReady = ok);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Model wajah belum siap. Silakan restart aplikasi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('[CameraFace] face service init error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat deteksi wajah: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _startLiveness() {
    setState(() {
      _livenessActive = true;
      _livenessDone = false;
      _currentChallengeIndex = 0;
      _challengeCompleted = false;
      _progress = 0.0;
      _challengeAttempts = 0;
      _firstTurnDirection = null;
      _showSkip = false;
    });

    _presentChallenge(_currentChallengeIndex);

    // After a grace period, allow skipping liveness so users are never stuck
    // (e.g. very dim lighting / unsupported device).
    _showSkipTimer?.cancel();
    _showSkipTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && _livenessActive && !_livenessDone && !_showSkip) {
        setState(() => _showSkip = true);
      }
    });
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!mounted || _capturing) return;
      if (_challengeCompleted || _livenessDone) return;

      _challengeAttempts++;
      if (_challengeAttempts > _maxAttemptsPerChallenge) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pastikan wajah terlihat jelas dan cahaya cukup, lalu ikuti instruksi putar kepala.',
              ),
            ),
          );
        }
        _challengeAttempts = 0;
      }

      await _analyzeFrame();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
  }

  void _presentChallenge(int index) {
    if (!mounted) return;
    final challenge = _challenges[index];
    ref.read(faceEnrollmentProvider.notifier).setLivenessChallenge(
          challenge.instruction,
        );
  }

  Future<void> _analyzeFrame() async {
    if (_analyzing) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    _analyzing = true;
    XFile? image;
    try {
      image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      final faceService = ref.read(faceServiceProvider);
      final analysis = await faceService.analyzeFace(bytes);
      _setFaceDetected(analysis != null);

      // Run head-turn liveness against the detected face.
      if (_livenessActive && !_challengeCompleted && analysis != null) {
        if (_passLivenessTurn(analysis.yaw)) {
          _completeChallenge();
        }
      }
    } on CameraException catch (_) {
      // Camera busy (previous capture not finished) — safe to ignore & retry.
    } catch (e) {
      debugPrint('[CameraFace] analyzeFrame error: $e');
    } finally {
      if (mounted) _analyzing = false;
      if (image != null) {
        try {
          await File(image.path).delete();
        } catch (_) {}
      }
    }
  }

  /// Decide whether the current head-pose [yaw] satisfies the active turn
  /// challenge. Direction handling is mirror-robust: the first challenge
  /// accepts a turn in EITHER direction (remembering which one); the second
  /// challenge requires the OPPOSITE turn, so a mirrored front-camera preview
  /// still validates genuine back-and-forth head movement.
  bool _passLivenessTurn(double yaw) {
    if (yaw.abs() < _yawThreshold) return false;
    final dir = yaw < 0 ? 'left' : 'right';
    if (_firstTurnDirection == null) {
      _firstTurnDirection = dir;
      return true;
    }
    return dir != _firstTurnDirection;
  }

  void _setFaceDetected(bool detected) {
    if (!mounted || _faceDetected == detected) return;
    setState(() => _faceDetected = detected);
  }

  void _completeChallenge() {
    if (!mounted) return;
    setState(() {
      _challengeCompleted = true;
      _challengeAttempts = 0;
      _progress = (_currentChallengeIndex + 1) / _challenges.length;
    });

    ref.read(faceEnrollmentProvider.notifier).completeLiveness();

    if ((_currentChallengeIndex + 1) < _challenges.length) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _currentChallengeIndex++;
          _challengeCompleted = false;
          _faceDetected = false;
        });
        _presentChallenge(_currentChallengeIndex);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _finishLiveness();
      });
    }
  }

  void _finishLiveness() {
    _stopPolling();
    setState(() {
      _livenessActive = false;
      _livenessDone = true;
      _showSkip = false;
    });
    // Brief grace so the user can face forward before the final capture.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && !_capturing) _capturePhoto();
    });
  }

  Future<void> _capturePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _capturing) {
      return;
    }

    setState(() => _capturing = true);

    XFile? image;
    try {
      image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      // Confirm a face is present in the final frame.
      final faceService = ref.read(faceServiceProvider);
      final analysis = await faceService.analyzeFace(bytes);
      if (!mounted) return;

      if (analysis == null || !analysis.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Wajah tidak terdeteksi. Coba lagi.'),
            backgroundColor: AppColors.error,
          ),
        );
        if (mounted) setState(() => _capturing = false);
        return;
      }

      widget.onFaceCaptured(bytes);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _capturing = false);
      }
    } finally {
      if (image != null) {
        try {
          await File(image.path).delete();
        } catch (_) {}
      }
    }
  }

  String _getChallengeInstruction() {
    if (!_livenessActive) return 'Posisikan wajah Anda di dalam bingkai';
    if (_livenessDone) return 'Luruskan wajah ke kamera';
    if (_challengeCompleted) return 'Selamat!';

    final challenge = _challenges[_currentChallengeIndex];
    final remaining = (_challenges.length - _currentChallengeIndex - 1)
        .clamp(0, _challenges.length - 1);
    return '${challenge.instruction}\n($remaining tersisa)';
  }

  IconData _getChallengeIcon() {
    final challenge = _challenges[_currentChallengeIndex];
    switch (challenge.type) {
      case LivenessChallengeType.turnLeft:
        return Icons.rotate_left;
      case LivenessChallengeType.turnRight:
        return Icons.rotate_right;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _showSkipTimer?.cancel();
    SystemChrome.setPreferredOrientations([]);
    _controller?.dispose();
    // The face service is app-scoped (disposed via its Riverpod provider),
    // so do NOT dispose it here — callers reuse it after pop.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isReady = _cameraReady && _faceServiceReady;

    if (!isReady || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            widget.isEnrollment ? 'Daftar Wajah' : 'Absen Wajah',
          ),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                _faceServiceReady
                    ? 'Memulai kamera...'
                    : 'Mempersiapkan deteksi wajah...',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller!.value.hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            widget.isEnrollment ? 'Daftar Wajah' : 'Absen Wajah',
          ),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Kamera tidak dapat diakses: '
              '${_controller!.value.errorDescription ?? 'silakan cek izin kamera'}',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final borderColor = _faceDetected
        ? (_challengeCompleted ? AppColors.success : Colors.white)
        : Colors.white;

    final borderWidth = _faceDetected ? 4.0 : 2.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.isEnrollment ? 'Daftar Wajah' : 'Absen Wajah',
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: widget.requireLiveness
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _livenessDone
                    ? null
                    : () {
                        _stopPolling();
                        Navigator.pop(context, false);
                      },
              )
            : null,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          Center(
            child: Container(
              width: 280,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Visibility(
                visible: !_faceDetected,
                child: const Icon(
                  Icons.face_retouching_natural,
                  size: 60,
                  color: Colors.white30,
                ),
              ),
            ),
          ),

          if (_livenessActive)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: _buildChallengeBanner(theme),
            ),

          if (_livenessActive)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: _buildProgress(),
            ),

          // Skip fallback (only shown after a grace period with no progress)
          if (_showSkip)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  onPressed: _livenessDone
                      ? null
                      : () {
                          _stopPolling();
                          _finishLiveness();
                        },
                  icon: const Icon(
                    Icons.face_unlock_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  label: const Text(
                    'Lewati',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: _capturing
                  ? const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : _buildCaptureFab(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _challengeCompleted
            ? AppColors.success.withValues(alpha: 0.9)
            : AppColors.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            _getChallengeIcon(),
            size: 32,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            _getChallengeInstruction(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 60),
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
      child: AnimatedFractionallySizedBox(
        widthFactor: _progress,
        alignment: Alignment.centerLeft,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureFab(ThemeData theme) {
    final bool canManualCapture =
        _faceDetected && !widget.requireLiveness && !_livenessActive;

    return FloatingActionButton(
      onPressed: canManualCapture ? _capturePhoto : null,
      backgroundColor: _faceDetected
          ? AppColors.primary
          : theme.colorScheme.onSurfaceVariant,
      foregroundColor: Colors.white,
      child: const Icon(Icons.camera_alt, size: 32),
    );
  }
}
