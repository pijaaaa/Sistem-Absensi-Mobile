import 'package:mobile/features/face/data/face_service.dart';

/// Web stub for face service — only returns web-compatible messages
class StubFaceService implements BaseFaceService {
  @override
  String get modelVersion => BaseFaceService.modelVersion;

  @override
  Future<bool> initialize() async {
    return false;
  }

  @override
  Future<List<double>?> detectFace(List<int> imageData) async {
    return null;
  }

  @override
  Future<List<double>?> extractEmbedding(List<int> imageData) async {
    return null;
  }

  @override
  double match(List<double> stored, List<double> live) => 0.0;

  @override
  void dispose() {}
}
