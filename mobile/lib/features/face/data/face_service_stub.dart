import 'package:mobile/features/face/data/face_service.dart';

/// Web stub for face service — no on-device face detection on web.
class StubFaceService implements BaseFaceService {
  @override
  Future<bool> initialize() async => false;

  @override
  Future<FaceAnalysis?> analyzeFace(List<int> imageData) async => null;

  @override
  void dispose() {}
}
