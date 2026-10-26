import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mobile/features/face/data/face_service.dart';

/// On-device face detection & liveness using Google ML Kit.
///
/// ML Kit reports `headEulerAngleY` (yaw) directly, which we use for the
/// left/right head-turn liveness challenge. Its on-device model is provided
/// via Google Play Services (Android) / the iOS ML Kit framework, so — unlike
/// dartcv4's OpenCV `face` module (which dartcv4 forces OFF) — it works without
/// any CMake native-asset build.
class MlKitFaceService implements BaseFaceService {
  FaceDetector? _detector;
  bool _isInitialized = false;
  String? _tempDir;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableClassification: true,
          performanceMode: FaceDetectorMode.accurate,
          minFaceSize: 0.1,
        ),
      );
      _tempDir = (await getTemporaryDirectory()).path;
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('[MlKitFace] init error: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Writes [imageData] (a JPEG) to a temporary file and returns its path.
  Future<File> _writeTempImage(Uint8List imageData) async {
    assert(_tempDir != null, 'Face service not initialized');
    final name = 'face_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final file = File('$_tempDir/$name');
    await file.writeAsBytes(imageData, flush: true);
    return file;
  }

  /// Detect faces in a JPEG image (given as bytes). Returns the list of faces.
  Future<List<Face>> _detect(Uint8List imageData) async {
    final detector = _detector;
    if (detector == null || !_isInitialized) return [];

    final file = await _writeTempImage(imageData);
    try {
      final input = InputImage.fromFilePath(file.path);
      return await detector.processImage(input);
    } finally {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  @override
  Future<FaceAnalysis?> analyzeFace(List<int> imageData) async {
    if (!_isInitialized || _detector == null) return null;
    try {
      final faces = await _detect(Uint8List.fromList(imageData));
      // Liveness/enrollment expects a single face in frame.
      if (faces.length > 1) return null;
      if (faces.isEmpty) return null;

      final face = faces.first;
      final box = face.boundingBox;
      return FaceAnalysis(
        centerX: box.left + box.width / 2,
        centerY: box.top + box.height / 2,
        width: box.width.toDouble(),
        height: box.height.toDouble(),
        yaw: face.headEulerAngleY ?? 0.0,
        leftEyeOpenProb: face.leftEyeOpenProbability,
        rightEyeOpenProb: face.rightEyeOpenProbability,
      );
    } catch (e) {
      debugPrint('[MlKitFace] analyzeFace error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _detector?.close();
    _detector = null;
    _isInitialized = false;
    _tempDir = null;
  }
}
