import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/features/face/presentation/providers/face_providers.dart';

class CameraFaceScreen extends ConsumerStatefulWidget {
  final Function(Uint8List imageBytes, double faceScore) onFaceCaptured;
  final bool requireLiveness;

  const CameraFaceScreen({
    super.key,
    required this.onFaceCaptured,
    this.requireLiveness = true,
  });

  @override
  ConsumerState<CameraFaceScreen> createState() => _CameraFaceScreenState();
}

class _CameraFaceScreenState extends ConsumerState<CameraFaceScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _faceDetected = false;
  String _instruction = 'Posisikan wajah di dalam bingkai';
  int _currentChallengeIndex = 0;
  Timer? _captureTimer;

  final List<String> _challenges = [
    'Posisikan wajah di dalam bingkai',
    'Wajah terdeteksi, tahan posisi...',
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startFaceDetection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _startFaceDetection() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _captureTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || _isDetecting) return;
      _detectFace();
    });
  }

  Future<void> _detectFace() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDetecting) {
      return;
    }

    _isDetecting = true;

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      
      final faceService = ref.read(faceServiceProvider);
      final faceCoords = await faceService.detectFace(bytes);

      if (!mounted) return;

      if (faceCoords != null) {
        if (!_faceDetected) {
          setState(() {
            _faceDetected = true;
            _instruction = _challenges[1];
          });

          // Auto-capture after 1 second if face is detected
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _faceDetected) {
              _captureFace();
            }
          });
        }
      } else {
        setState(() {
          _faceDetected = false;
          _instruction = _challenges[0];
        });
      }
    } catch (e) {
      // Silent fail for detection errors during preview
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _captureFace() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _captureTimer?.cancel();

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
          setState(() {
            _faceDetected = false;
            _instruction = _challenges[0];
          });
          _startFaceDetection();
        }
        return;
      }

      // For now, return dummy score. Real matching happens in flow service
      widget.onFaceCaptured(bytes, 0.95);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() {
          _faceDetected = false;
          _instruction = _challenges[0];
        });
        _startFaceDetection();
      }
    }
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isInitialized || _controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Verifikasi Wajah'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Verifikasi Wajah'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // Face Overlay
          Center(
            child: Container(
              width: 280,
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _faceDetected ? AppColors.success : Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(180),
              ),
            ),
          ),

          // Instruction
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _instruction,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Manual Capture Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _faceDetected ? _captureFace : null,
                backgroundColor: _faceDetected ? AppColors.success : Colors.grey,
                child: const Icon(Icons.camera_alt, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
