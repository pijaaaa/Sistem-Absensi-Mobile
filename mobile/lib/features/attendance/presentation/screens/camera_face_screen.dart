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

class _CameraFaceScreenState extends ConsumerState<CameraFaceScreen>
    with TickerProviderStateMixin {
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
  int? _lockedTrackingId;
  static const double _centerYawTolerance = 8.0;
  bool _returningToCenter = false;
  String? _firstTurnDirection;

  static const int _maxAttemptsPerChallenge = 10;
  static const _pollInterval = Duration(milliseconds: 700);
  static const double _yawThreshold = 12.0;

  late final List<LivenessChallenge> _challenges;

  // Animation controllers for laser scanning & glowing frame
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _challenges = _buildChallenges();

    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );

    _initialize();
  }

  List<LivenessChallenge> _buildChallenges() {
    return [
      LivenessChallenge(
        type: LivenessChallengeType.turnLeft,
        instruction: 'Putar kepala ke Kanan',
        semanticLabel: 'Tantangan putar kepala ke kiri',
      ),
      LivenessChallenge(
        type: LivenessChallengeType.turnRight,
        instruction: 'Putar kepala ke Kiri',
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

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
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
      _lockedTrackingId = null;
      _returningToCenter = false;
      _showSkip = false;
    });

    _presentChallenge(_currentChallengeIndex);

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

      if (_livenessActive && !_challengeCompleted && analysis != null) {
        if (!analysis.isValid) return;

        if (_lockedTrackingId == null && analysis.trackingId != null) {
          _lockedTrackingId = analysis.trackingId;
        } else if (_lockedTrackingId != null && analysis.trackingId != null && analysis.trackingId != _lockedTrackingId) {
          return;
        }

        if (_passLivenessTurnWithCenterCheck(analysis.yaw)) {
          _completeChallenge();
        }
      }
    } on CameraException catch (_) {
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

  bool _passLivenessTurnWithCenterCheck(double yaw) {
    if (_returningToCenter) {
      if (yaw.abs() <= _centerYawTolerance) {
        _returningToCenter = false;
        return true;
      }
      return false;
    }

    if (yaw.abs() < _yawThreshold) return false;
    final dir = yaw < 0 ? 'left' : 'right';
    final targetDir = _challenges[_currentChallengeIndex].type == LivenessChallengeType.turnLeft ? 'left' : 'right';

    if (dir == targetDir) {
      _returningToCenter = true;
      return false;
    }
    return false;
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

      final faceService = ref.read(faceServiceProvider);
      final analysis = await faceService.analyzeFace(bytes);
      if (!mounted) return;

      if (analysis == null || !analysis.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wajah tidak terdeteksi. Coba lagi.'),
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
    if (!_livenessActive) return 'Posisikan wajah Anda di dalam bingkai oval';
    if (_livenessDone) return 'Luruskan wajah ke kamera';
    if (_challengeCompleted) return 'Bagus!';
    if (_returningToCenter) return 'Kembalikan posisi wajah ke tengah';

    final challenge = _challenges[_currentChallengeIndex];
    return challenge.instruction;
  }

  @override
  void dispose() {
    _stopPolling();
    _showSkipTimer?.cancel();
    _scannerController.dispose();
    SystemChrome.setPreferredOrientations([]);
    _controller?.dispose();
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
          title: Text(widget.isEnrollment ? 'Daftar Wajah' : 'Absen Wajah'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Memuat kamera & AI wajah...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.isEnrollment ? 'Daftar Wajah' : 'Absen Wajah'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _livenessDone
              ? null
              : () {
                  _stopPolling();
                  Navigator.pop(context, false);
                },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Crisp Camera Preview
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // Modern Face Scanner UI (Overlay & Glowing Rounded Oval Frame)
          Center(
            child: SizedBox(
              width: 280,
              height: 380,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glowing Rounded Face Frame
                  AnimatedBuilder(
                    animation: _scannerAnimation,
                    builder: (context, child) {
                      final activeColor = _faceDetected
                          ? (_challengeCompleted ? AppColors.success : AppColors.primary)
                          : Colors.white70;

                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(140),
                          border: Border.all(
                            color: activeColor,
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Animated Scanning Laser Line
                  if (_livenessActive && !_challengeCompleted)
                    AnimatedBuilder(
                      animation: _scannerAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: _scannerAnimation.value * 340 + 20,
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Center indicator icon when no face detected
                  if (!_faceDetected)
                    const Icon(
                      Icons.face,
                      size: 64,
                      color: Colors.white24,
                    ),
                ],
              ),
            ),
          ),

          // Progress Steps Indicator (Front / Left / Right poses)
          if (_livenessActive)
            Positioned(
              top: 110,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(1, 'Depan', _currentChallengeIndex >= 0),
                  _buildStepIndicatorConnector(_currentChallengeIndex >= 1),
                  _buildStepIndicator(2, 'Kanan', _currentChallengeIndex >= 1),
                  _buildStepIndicatorConnector(_currentChallengeIndex >= 2),
                  _buildStepIndicator(3, 'Kiri', _livenessDone),
                ],
              ),
            ),

          // Clear Instruction Text Box
          Positioned(
            top: 175,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                _getChallengeInstruction(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Skip button fallback if needed
          if (_showSkip)
            Positioned(
              bottom: 40,
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
                    Icons.skip_next_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  label: const Text(
                    'Lewati Liveness',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ),

          // Capturing indicator
          if (_capturing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepNumber, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : Colors.white24,
            border: Border.all(
              color: isActive ? Colors.white : Colors.white38,
              width: 2,
            ),
          ),
          child: Center(
            child: isActive && stepNumber <= (_currentChallengeIndex + 1)
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicatorConnector(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      color: isActive ? AppColors.primary : Colors.white24,
    );
  }
}
