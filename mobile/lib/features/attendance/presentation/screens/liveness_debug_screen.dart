import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/face/data/face_service.dart';
import 'package:mobile/features/face/presentation/providers/face_providers.dart';

class LivenessDebugScreen extends ConsumerStatefulWidget {
  const LivenessDebugScreen({super.key});

  @override
  ConsumerState<LivenessDebugScreen> createState() => _LivenessDebugScreenState();
}

class _LivenessDebugScreenState extends ConsumerState<LivenessDebugScreen> {
  CameraController? _controller;
  bool _cameraReady = false;
  bool _faceServiceReady = false;

  Timer? _pollTimer;
  bool _analyzing = false;
  FaceAnalysis? _lastAnalysis;

  // Challenge test state
  int _currentChallengeIndex = 0;
  bool _challengeCompleted = false;
  String? _firstTurnDirection;
  bool _returningToCenter = false;

  static const _pollInterval = Duration(milliseconds: 500);
  static const double _yawThreshold = 12.0;
  static const double _centerYawTolerance = 8.0;

  final List<String> _challenges = ['Putar Kepala ke Kiri', 'Putar Kepala ke Kanan'];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final faceService = ref.read(faceServiceProvider);
    final ok = await faceService.initialize();
    if (!mounted) return;
    setState(() => _faceServiceReady = ok);

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);

      _startPolling();
    } catch (e) {
      debugPrint('[LivenessDebug] init error: $e');
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!mounted || _analyzing || _controller == null || !_controller!.value.isInitialized) return;
      _analyzing = true;
      XFile? image;
      try {
        image = await _controller!.takePicture();
        final bytes = await image.readAsBytes();
        final faceService = ref.read(faceServiceProvider);
        final analysis = await faceService.analyzeFace(bytes);

        if (mounted) {
          setState(() {
            _lastAnalysis = analysis;
          });

          if (analysis != null && !_challengeCompleted) {
            _evaluateChallenge(analysis.yaw);
          }
        }
      } catch (e) {
        debugPrint('[LivenessDebug] poll error: $e');
      } finally {
        _analyzing = false;
        if (image != null) {
          try {
            await File(image.path).delete();
          } catch (_) {}
        }
      }
    });
  }

  void _evaluateChallenge(double yaw) {
    if (_returningToCenter) {
      if (yaw.abs() <= _centerYawTolerance) {
        setState(() {
          _returningToCenter = false;
          if (_currentChallengeIndex < _challenges.length - 1) {
            _currentChallengeIndex++;
          } else {
            _challengeCompleted = true;
          }
        });
      }
      return;
    }

    if (yaw.abs() < _yawThreshold) return;
    final dir = yaw < 0 ? 'left' : 'right';

    if (_currentChallengeIndex == 0) {
      if (_firstTurnDirection == null) {
        _firstTurnDirection = dir;
      }
      if (dir == _firstTurnDirection) {
        setState(() => _returningToCenter = true);
      }
    } else {
      if (_firstTurnDirection != null && dir != _firstTurnDirection) {
        setState(() => _returningToCenter = true);
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('Debug mode only')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liveness & Yaw Engine Debug (Fase W3)'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: (!_cameraReady || !_faceServiceReady || _controller == null)
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _challengeCompleted
                              ? 'Liveness Challenge PASSED!'
                              : _returningToCenter
                                  ? 'Kembalikan Posisi Wajah ke Tengah'
                                  : 'Instruksi: ${_challenges[_currentChallengeIndex]}',
                          style: TextStyle(
                            color: _challengeCompleted ? AppColors.success : Colors.yellow,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(color: Colors.white54),
                        Text('Face Detected: ${_lastAnalysis != null ? "Yes" : "No"}', style: const TextStyle(color: Colors.white)),
                        Text('Face Count: ${_lastAnalysis?.faceCount ?? 0}', style: const TextStyle(color: Colors.white)),
                        Text('Yaw (MLKit/Effective): ${_lastAnalysis?.yaw.toStringAsFixed(2) ?? "-"}°', style: const TextStyle(color: Colors.white)),
                        Text('Yaw Landmark Ratio: ${_lastAnalysis?.yawLandmark.formatDecimal() ?? _lastAnalysis?.yawLandmark.toStringAsFixed(2) ?? "-"}', style: const TextStyle(color: Colors.white)),
                        Text('Tracking ID (Identity Lock): ${_lastAnalysis?.trackingId ?? "-"}', style: const TextStyle(color: Colors.white)),
                        Text('Quality - Sharpness: ${_lastAnalysis?.sharpness.toStringAsFixed(1) ?? "-"}', style: const TextStyle(color: Colors.white)),
                        Text('Quality - Illumination: ${_lastAnalysis?.illumination.toStringAsFixed(1) ?? "-"}', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () {
                      setState(() {
                        _currentChallengeIndex = 0;
                        _challengeCompleted = false;
                        _firstTurnDirection = null;
                        _returningToCenter = false;
                      });
                    },
                    child: const Text('Reset Challenge Test', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
    );
  }
}

extension on double {
  String formatDecimal() => toStringAsFixed(2);
}
