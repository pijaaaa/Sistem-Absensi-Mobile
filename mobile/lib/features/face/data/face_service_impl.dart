import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:mobile/features/face/data/face_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

/// Mobile face service implementation using OpenCV (YuNet + SFace)
class MobileFaceService implements BaseFaceService {
  cv.FaceDetectorYN? _detector;
  cv.FaceRecognizerSF? _recognizer;
  bool _isInitialized = false;

  @override
  String get modelVersion => BaseFaceService.modelVersion;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Load models from assets to temp directory
      final tempDir = await getTemporaryDirectory();
      final detectorPath = '${tempDir.path}/${BaseFaceService.detectorModel}';
      final recognizerPath = '${tempDir.path}/${BaseFaceService.recognizerModel}';

      // Copy detector model
      if (!File(detectorPath).existsSync()) {
        final detectorData = await rootBundle.load('assets/models/${BaseFaceService.detectorModel}');
        await File(detectorPath).writeAsBytes(detectorData.buffer.asUint8List());
      }

      // Copy recognizer model
      if (!File(recognizerPath).existsSync()) {
        final recognizerData = await rootBundle.load('assets/models/${BaseFaceService.recognizerModel}');
        await File(recognizerPath).writeAsBytes(recognizerData.buffer.asUint8List());
      }

      // Initialize detector (YuNet)
      _detector = cv.FaceDetectorYN.fromFile(
        detectorPath,
        '',
        (320, 320),
      );

      // Initialize recognizer (SFace)
      _recognizer = cv.FaceRecognizerSF.fromFile(
        recognizerPath,
        '',
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Face service initialization error: $e');
      }
      return false;
    }
  }

  @override
  Future<List<double>?> detectFace(List<int> imageData) async {
    if (!_isInitialized || _detector == null) {
      throw Exception('Face service not initialized');
    }

    try {
      // Decode image
      final mat = cv.imdecode(Uint8List.fromList(imageData), cv.IMREAD_COLOR);
      
      // Set input size
      _detector!.setInputSize((mat.cols, mat.rows));
      
      // Detect faces
      final faces = _detector!.detect(mat);
      
      if (faces.rows == 0) {
        return null; // No face detected
      }
      
      if (faces.rows > 1) {
        throw Exception('Multiple faces detected. Please ensure only one face is visible.');
      }

      // Extract face coordinates (x, y, w, h)
      final faceData = <double>[];
      for (int i = 0; i < 4; i++) {
        faceData.add(faces.at<double>(0, i));
      }
      
      mat.dispose();
      faces.dispose();
      
      return faceData;
    } catch (e) {
      if (kDebugMode) {
        print('Face detection error: $e');
      }
      return null;
    }
  }

  @override
  Future<List<double>?> extractEmbedding(List<int> imageData) async {
    if (!_isInitialized || _detector == null || _recognizer == null) {
      throw Exception('Face service not initialized');
    }

    try {
      // Decode image
      final mat = cv.imdecode(Uint8List.fromList(imageData), cv.IMREAD_COLOR);
      
      // Set input size
      _detector!.setInputSize((mat.cols, mat.rows));
      
      // Detect faces
      final faces = _detector!.detect(mat);
      
      if (faces.rows == 0) {
        mat.dispose();
        faces.dispose();
        return null;
      }
      
      if (faces.rows > 1) {
        mat.dispose();
        faces.dispose();
        throw Exception('Multiple faces detected');
      }

      // Align face
      final alignedFace = _recognizer!.alignCrop(mat, faces);
      
      // Extract feature/embedding
      final feature = _recognizer!.feature(alignedFace);
      
      // Convert Mat to List<double>
      final embedding = <double>[];
      for (int i = 0; i < feature.cols; i++) {
        embedding.add(feature.at<double>(0, i));
      }
      
      mat.dispose();
      faces.dispose();
      alignedFace.dispose();
      feature.dispose();
      
      return embedding;
    } catch (e) {
      if (kDebugMode) {
        print('Embedding extraction error: $e');
      }
      return null;
    }
  }

  @override
  double match(List<double> stored, List<double> live) {
    if (_recognizer == null || !_isInitialized) {
      return 0.0;
    }

    try {
      // Convert to Mat
      final storedMat = cv.Mat.fromList(
        1,
        stored.length,
        cv.MatType.CV_64FC1,
        stored,
      );
      
      final liveMat = cv.Mat.fromList(
        1,
        live.length,
        cv.MatType.CV_64FC1,
        live,
      );

      // Calculate cosine similarity
      final score = _recognizer!.match(storedMat, liveMat, disType: cv.FaceRecognizerSF.FR_COSINE);
      
      storedMat.dispose();
      liveMat.dispose();
      
      return score;
    } catch (e) {
      if (kDebugMode) {
        print('Face matching error: $e');
      }
      return 0.0;
    }
  }

  @override
  void dispose() {
    _detector?.dispose();
    _recognizer?.dispose();
    _isInitialized = false;
  }
}
