/// Result of an on-device face analysis.
///
/// [centerX]/[centerY]/[width]/[height] describe the face bounding box in image
/// pixels. [yaw] is the horizontal head rotation in degrees reported by ML Kit
/// (negative = face turned to the left side of the image, positive = right).
/// [leftEyeOpenProb] / [rightEyeOpenProb] are blink probabilities (0..1) when
/// classification is enabled, otherwise `null`.
class FaceAnalysis {
  final double centerX;
  final double centerY;
  final double width;
  final double height;
  final double yaw;
  final double? leftEyeOpenProb;
  final double? rightEyeOpenProb;

  FaceAnalysis({
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    required this.yaw,
    this.leftEyeOpenProb,
    this.rightEyeOpenProb,
  });

  bool get isValid => width > 0 && height > 0;
}

/// Abstract interface for on-device face detection / liveness.
///
/// Embedding extraction and face matching are NOT done on-device (the OpenCV
/// `face` module — YuNet/SFace — is unavailable with dartcv4, whose native
/// build forces `BUILD_opencv_face OFF`). Those operations are delegated to the
/// backend `/face/*` endpoints (see [FaceDataSource]).
abstract class BaseFaceService {
  Future<bool> initialize();

  /// Detect the (single) face in [imageData] and return its analysis, or
  /// `null` when no face is found.
  Future<FaceAnalysis?> analyzeFace(List<int> imageData);

  void dispose();
}
