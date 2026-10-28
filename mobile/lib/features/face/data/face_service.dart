/// Result of an on-device face analysis.
///
/// [centerX]/[centerY]/[width]/[height] describe the face bounding box in image
/// pixels. [yaw] is the horizontal head rotation in degrees reported by ML Kit
/// or computed via 5 facial landmarks (nose vs eyes midpoint ratio).
/// [leftEyeOpenProb] / [rightEyeOpenProb] are blink probabilities (0..1) when
/// classification is enabled, otherwise `null`.
/// [yawLandmark] is the landmark-derived yaw ratio for Phase W3 requirement 1.
/// [faceCount] is the number of faces detected (quality gate requirement 4).
/// [sharpness] is the estimated image blur/sharpness score (quality gate requirement 4).
/// [illumination] is the average pixel intensity / brightness (quality gate requirement 4).
/// [trackingId] is the stable ID used for identity consistency lock across steps (requirement 3).
class FaceAnalysis {
  final double centerX;
  final double centerY;
  final double width;
  final double height;
  final double yaw;
  final double? leftEyeOpenProb;
  final double? rightEyeOpenProb;
  final double yawLandmark;
  final int faceCount;
  final double sharpness;
  final double illumination;
  final int? trackingId;

  FaceAnalysis({
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    required this.yaw,
    this.leftEyeOpenProb,
    this.rightEyeOpenProb,
    this.yawLandmark = 0.0,
    this.faceCount = 1,
    this.sharpness = 100.0,
    this.illumination = 128.0,
    this.trackingId,
  });

  bool get isValid => width > 0 && height > 0 && faceCount == 1;
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
