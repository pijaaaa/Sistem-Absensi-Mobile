/// Abstract interface for face service
/// Platform-specific implementation:
/// - mobile: face_service_impl.dart (uses opencv_dart)
/// - web: face_service_stub.dart (placeholder)
abstract class BaseFaceService {
  static const String detectorModel = 'face_detection_yunet_2023mar.onnx';
  static const String recognizerModel = 'face_recognition_sface_2021dec.onnx';
  String get modelVersion;

  Future<bool> initialize();
  Future<List<double>?> detectFace(List<int> imageData);
  Future<List<double>?> extractEmbedding(List<int> imageData);
  double match(List<double> stored, List<double> live);
  Future<bool> detectEyeBlink(List<int> imageData, {bool isOpen = true});
  Future<bool> detectHeadTurn(List<int> imageData, {required String direction});
  void dispose();
}
