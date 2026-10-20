import 'dart:typed_data';
import 'package:flutter/foundation.dart';
// import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:mobile/features/face/data/face_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

/// Mobile face service implementation using OpenCV (YuNet + SFace)
/// TEMPORARILY DISABLED - opencv_dart build conflict
class MobileFaceService implements BaseFaceService {
  // cv.FaceDetectorYN? _detector;
  // cv.FaceRecognizerSF? _recognizer;
  bool _isInitialized = false;

  @override
  String get modelVersion => BaseFaceService.modelVersion;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    // TODO: Re-enable when opencv_dart is fixed
    _isInitialized = true;
    return true;
  }

  @override
  Future<List<double>?> detectFace(List<int> imageData) async {
    // Stub: return dummy coordinates
    return [100.0, 100.0, 200.0, 200.0];
  }

  @override
  Future<List<double>?> extractEmbedding(List<int> imageData) async {
    // Stub: return dummy embedding
    return List.generate(128, (i) => 0.5);
  }

  @override
  double match(List<double> stored, List<double> live) {
    // Stub: return high score
    return 0.95;
  }

  @override
  void dispose() {
    _isInitialized = false;
  }
}
