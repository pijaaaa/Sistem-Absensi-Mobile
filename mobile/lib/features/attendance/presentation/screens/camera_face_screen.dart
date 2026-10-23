import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/face/presentation/providers/face_providers.dart';

enum LivenessChallengeType { blink, turnLeft, turnRight }

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
  final Function(Uint8List imageBytes, double faceScore) onFaceCaptured;
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
  bool _isInitialized = false;

  bool _faceDetected = false;
  bool _livenessActive = false;
  int _currentChallengeIndex = 0;
  bool _challengeCompleted = false;
  double _progress = 0.0;
  bool _capturing = false;

  late final List<LivenessChallenge> _challenges;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _challenges = _buildChallenges();

    _initializeCamera();
  }

  List<LivenessChallenge> _buildChallenges() {
    return [
      LivenessChallenge(
        type: LivenessChallengeType.blink,
        instruction: 'Kedipkan mata Anda',
        semanticLabel: 'Tantangan kedip mata',
      ),
      LivenessChallenge(
        type: LivenessChallengeType.turnLeft,
        instruction: 'Putar kepala ke kiri',
        semanticLabel: 'Tantangan putar kepala ke kiri',
      ),
      LivenessChallenge(
        type: LivenessChallengeType.blink,
        instruction: 'Kedipkan mata lagi',
        semanticLabel: 'Tantangan kedip mata kedua',
      ),
      LivenessChallenge(
        type: LivenessChallengeType.turnRight,
        instruction: 'Putar kepala ke kanan',
        semanticLabel: 'Tantangan putar kepala ke kanan',
      ),
    ];
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final imageFormat = Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.jpeg;

      // Use low resolution for better performance on older devices
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: imageFormat,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        if (widget.requireLiveness) {
          _startLiveness();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error kamera: ${e.toString()}')),
        );
      }
    }
  }

  void _startLiveness() {
    setState(() {
      _livenessActive = true;
      _currentChallengeIndex = 0;
      _progress = 0.0;
    });

    _presentChallenge(_currentChallengeIndex);
  }

  void _presentChallenge(int index) {
    final challenge = _challenges[index];
    ref.read(faceEnrollmentProvider.notifier).setLivenessChallenge(
          challenge.instruction,
        );
  }

  Future<void> _processFrame() async {
    if (!_faceDetected || _challengeCompleted || _capturing) return;

    final challenge = _challenges[_currentChallengeIndex];
    final passed = await _simulateChallengeDetection(challenge);

    if (passed && mounted) {
      setState(() {
        _challengeCompleted = true;
        _progress = (_currentChallengeIndex + 1) / _challenges.length;
      });

      if ((_currentChallengeIndex + 1) < _challenges.length) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _currentChallengeIndex++;
              _challengeCompleted = false;
            });
            _presentChallenge(_currentChallengeIndex);
          }
        });
      } else {
        _captureFace();
      }
    }
  }

  Future<bool> _simulateChallengeDetection(LivenessChallenge challenge) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _faceDetected;
  }

  Future<void> _captureFace() async {
    if (_controller == null || !_controller!.value.isInitialized || _capturing) return;

    setState(() => _capturing = true);

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      final faceService = ref.read(faceServiceProvider);
      final embedding = await faceService.extractEmbedding(bytes);

      if (embedding == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wajah tidak terdeteksi. Coba lagi.')),
          );
        }
        setState(() => _capturing = false);
        return;
      }

      final score = faceService.match(embedding, embedding);

      widget.onFaceCaptured(bytes, score);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
      setState(() => _capturing = false);
    }
  }

  // ignore: unused_element
  void _handleFaceDetection(bool detected) {
    if (mounted && widget.requireLiveness && _livenessActive) {
      setState(() {
        _faceDetected = detected;
      });

      if (detected && !_challengeCompleted) {
        _processFrame();
      }
    }
  }

  String _getChallengeInstruction() {
    if (!_livenessActive) return 'Posisikan wajah Anda di dalam bingkai';
    if (_challengeCompleted) return 'Selamat!';

    final challenge = _challenges[_currentChallengeIndex];
    final remaining = (_challenges.length - _currentChallengeIndex - 1).clamp(0, _challenges.length - 1);
    return '${challenge.instruction}\n($remaining tersisa)';
  }

  IconData _getChallengeIcon() {
    final challenge = _challenges[_currentChallengeIndex];
    switch (challenge.type) {
      case LivenessChallengeType.blink:
        return Icons.visibility;
      case LivenessChallengeType.turnLeft:
        return Icons.rotate_left;
      case LivenessChallengeType.turnRight:
        return Icons.rotate_right;
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([]);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Verifikasi Wajah'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_controller!.value.hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Verifikasi Wajah'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Kamera tidak dapat diakses: ${_controller!.value.errorDescription ?? 'silakan cek izin kamera'}',
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
              child: Container(
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
              ),
            ),

          if (_livenessActive)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Container(
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
                  : FloatingActionButton(
                      onPressed: _capturing ? null : _captureFace,
                      backgroundColor: _faceDetected
                          ? AppColors.primary
                          : theme.colorScheme.onSurfaceVariant,
                      foregroundColor: Colors.white,
                      child: Icon(
                        _livenessActive ? Icons.camera_alt : Icons.camera_alt,
                        size: 32,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
