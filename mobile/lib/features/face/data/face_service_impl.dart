import 'package:dartcv4/dartcv.dart' as cv;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/features/face/data/face_matcher.dart';
import 'package:mobile/features/face/data/face_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

/// Mobile face service implementation using OpenCV (YuNet + SFace)
/// Optimized for performance on older devices (Android 7, RAM 2GB)
class MobileFaceService implements BaseFaceService {
  cv.FaceDetectorYN? _detector;
  cv.FaceRecognizerSF? _recognizer;
  bool _isInitialized = false;
  String _modelPath = '';
  bool _useFastMode = false;

  @override
  String get modelVersion => 'sface-2021dec+yunet-2023mar';

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      _modelPath = docsDir.path;

      final detectorPath = '$_modelPath/${BaseFaceService.detectorModel}';
      final recognizerPath = '$_modelPath/${BaseFaceService.recognizerModel}';

      if (!File(detectorPath).existsSync() ||
          !File(recognizerPath).existsSync()) {
        await _copyModelsToDocuments();
      }

      _detector = cv.FaceDetectorYN.fromFile(
        detectorPath,
        '',
        (160, 120),
        scoreThreshold: 0.9,
        nmsThreshold: 0.3,
        topK: 5000,
        backendId: 0,
        targetId: 0,
      );

      _recognizer = cv.FaceRecognizerSF.fromFile(
        recognizerPath,
        '',
        backendId: 0,
        targetId: 0,
      );

      _isInitialized = true;
      _detectDevicePerformance();
      return true;
    } catch (e) {
      debugPrint('[FaceService] init error: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Detect device performance level and adjust processing mode
  void _detectDevicePerformance() {
    try {
      final deviceInfo = DeviceInfoPlugin();
      deviceInfo.androidInfo.then((info) {
        // physicalRamSize is in megabytes
        final isLowRam = info.isLowRamDevice || info.physicalRamSize < 3000; // < 3GB RAM
        final sdkVersion = info.version.sdkInt;
        
        if (isLowRam || sdkVersion < 28) {
          _useFastMode = true;
          debugPrint('[FaceService] Low-end device detected, using fast mode');
        }
      }).catchError((_) {});
    } catch (_) {
      // Default to normal mode
    }
  }

  /// Check if widget is still mounted (for async callbacks)
  bool get mounted => _isInitialized;

  Future<void> _copyModelsToDocuments() async {
    final modelsDir = _modelPath;

    if (!File('$modelsDir/${BaseFaceService.detectorModel}').existsSync()) {
      final data = await rootBundle.load(
          'assets/models/${BaseFaceService.detectorModel}');
      final bytes = data.buffer.asUint8List();
      await File('$modelsDir/${BaseFaceService.detectorModel}').writeAsBytes(bytes);
    }

    if (!File('$modelsDir/${BaseFaceService.recognizerModel}').existsSync()) {
      final data = await rootBundle.load(
          'assets/models/${BaseFaceService.recognizerModel}');
      final bytes = data.buffer.asUint8List();
      await File('$modelsDir/${BaseFaceService.recognizerModel}')
          .writeAsBytes(bytes);
    }
  }

  /// Resize image for faster processing on low-end devices
  List<int> _resizeImageForFastMode(List<int> imageData) {
    if (!_useFastMode) return imageData;
    
    try {
      final img = cv.imdecode(Uint8List.fromList(imageData), cv.IMREAD_COLOR);
      if (img.isEmpty) return imageData;
      
      // Resize to width 320 for faster face detection on low-end devices
      final resized = cv.resize(img, (320, 240));
      final encoded = cv.imencode('.jpg', resized);
      
      img.dispose();
      resized.dispose();
      
      // imencode returns (bool, Uint8List)
      return encoded.$2;
    } catch (e) {
      debugPrint('[FaceService] resize error: $e');
      return imageData;
    }
  }

  Future<cv.Mat?> _decodeImage(List<int> imageData) async {
    final img = cv.imdecode(Uint8List.fromList(imageData), cv.IMREAD_COLOR);
    if (img.isEmpty) return null;
    return img;
  }

  @override
  Future<List<double>?> detectFace(List<int> imageData) async {
    if (!_isInitialized || _detector == null) return null;

    cv.Mat? img;
    cv.Mat? faces;
    try {
      img = await _decodeImage(imageData);
      if (img == null) return null;

      faces = _detector!.detect(img);

      if (faces.rows == 0 || faces.cols == 0) {
        return null;
      }

      final result = <double>[];
      for (int i = 0; i < faces.cols; i++) {
        result.add(faces.at<double>(0, i));
      }

      return result;
    } catch (e) {
      debugPrint('[FaceService] detectFace error: $e');
      return null;
    } finally {
      img?.dispose();
      faces?.dispose();
    }
  }

  @override
  Future<List<double>?> extractEmbedding(List<int> imageData) async {
    if (!_isInitialized || _detector == null || _recognizer == null) {
      return null;
    }

    cv.Mat? img;
    cv.Mat? faces;
    cv.Mat? aligned;
    cv.Mat? features;
    try {
      // On low-end devices, resize image before processing to improve performance
      final processedImage = _useFastMode ? _resizeImageForFastMode(imageData) : imageData;
      
      img = await _decodeImage(processedImage);
      if (img == null) return null;

      faces = _detector!.detect(img);

      if (faces.rows == 0 || faces.cols == 0) {
        return null;
      }

      aligned = _recognizer!.alignCrop(img, faces.row(0));
      features = _recognizer!.feature(aligned);

      final embedding = <double>[];
      for (int i = 0; i < features.rows; i++) {
        embedding.add(features.at<double>(i, 0));
      }

      return embedding;
    } catch (e) {
      debugPrint('[FaceService] extractEmbedding error: $e');
      return null;
    } finally {
      img?.dispose();
      faces?.dispose();
      aligned?.dispose();
      features?.dispose();
    }
  }

  @override
  double match(List<double> stored, List<double> live) => faceDistance(stored, live);

  @override
  Future<bool> detectEyeBlink(List<int> imageData, {bool isOpen = true}) async {
    if (!_isInitialized || _detector == null) return false;

    cv.Mat? img;
    cv.Mat? faces;
    try {
      img = await _decodeImage(imageData);
      if (img == null) return false;

      faces = _detector!.detect(img);

      if (faces.rows == 0) {
        return false;
      }

      final coords = <double>[];
      for (int i = 0; i < faces.cols; i++) {
        coords.add(faces.at<double>(0, i));
      }

      if (coords.length < 10) return false;

      final eyeLeftX = (coords[2] + coords[4]) / 2;
      final eyeLeftY = (coords[3] + coords[5]) / 2;
      final eyeRightX = (coords[6] + coords[8]) / 2;
      final eyeRightY = (coords[7] + coords[9]) / 2;

      final eyeDistance = ((eyeRightX - eyeLeftX).abs() + (eyeRightY - eyeLeftY).abs()) / 2;
      final faceWidth = coords[2] - coords[0];
      final eyeToFaceRatio = faceWidth != 0 ? eyeDistance / faceWidth : 0;

      return isOpen ? eyeToFaceRatio > 0.15 : eyeToFaceRatio < 0.10;
    } catch (e) {
      debugPrint('[FaceService] detectEyeBlink error: $e');
      return false;
    } finally {
      img?.dispose();
      faces?.dispose();
    }
  }

  @override
  Future<bool> detectHeadTurn(List<int> imageData, {required String direction}) async {
    if (!_isInitialized || _detector == null) return false;

    cv.Mat? img;
    cv.Mat? faces;
    try {
      img = await _decodeImage(imageData);
      if (img == null) return false;

      faces = _detector!.detect(img);

      if (faces.rows == 0) {
        return false;
      }

      final coords = <double>[];
      for (int i = 0; i < faces.cols; i++) {
        coords.add(faces.at<double>(0, i));
      }

      if (coords.length < 10) return false;

      final noseX = coords[8];
      final leftEyeX = (coords[4] + coords[6]) / 2;
      final rightEyeX = (coords[4] + coords[6]) / 2;
      final centerX = (coords[0] + coords[2]) / 2;

      final noseOffset = noseX - centerX;
      final leftEyeOffset = leftEyeX - centerX;
      final rightEyeOffset = rightEyeX - centerX;

      if (direction == 'left') {
        return noseOffset < -0.05 && leftEyeOffset < -0.02;
      } else {
        return noseOffset > 0.05 && rightEyeOffset > 0.02;
      }
    } catch (e) {
      debugPrint('[FaceService] detectHeadTurn error: $e');
      return false;
    } finally {
      img?.dispose();
      faces?.dispose();
    }
  }

  @override
  void dispose() {
    _detector?.dispose();
    _recognizer?.dispose();
    _isInitialized = false;
  }
}
