import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mobile/core/constants/api_constants.dart';

abstract class FaceDataSource {
  Future<Map<String, dynamic>> enroll({
    List<Uint8List>? photos,
    List<List<double>>? embeddings,
    String? modelVersion,
  });

  /// Verify a captured face against the employee's stored template.
  ///
  /// Sends the [photo] to the backend `POST /face/verify` endpoint, which
  /// extracts the embedding server-side (via the face-service SFace model —
  /// on-device OpenCV `face` is unavailable because dartcv4 forces
  /// `BUILD_opencv_face OFF`) and matches it against the template stored for
  /// the authenticated employee.
  ///
  /// Returns the `data` payload: `{score, threshold, match, model_version}`.
  Future<Map<String, dynamic>> verify({required Uint8List photo});

  Future<List<double>?> downloadTemplate();

  /// Delete all stored face templates for the authenticated employee.
  /// The employee can re-enroll afterward.
  Future<Map<String, dynamic>> deleteFace();
}

class FaceDataSourceImpl implements FaceDataSource {
  final Dio dio;

  FaceDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> enroll({
    List<Uint8List>? photos,
    List<List<double>>? embeddings,
    String? modelVersion,
  }) async {
    if ((photos == null || photos.isEmpty) &&
        (embeddings == null || embeddings.isEmpty)) {
      throw ArgumentError('Harus kirim photos atau embeddings.');
    }

    final formData = FormData();

    if (modelVersion != null) {
      formData.fields.add(MapEntry('model_version', modelVersion));
    }

    if (embeddings != null) {
      formData.fields.add(MapEntry('embeddings', jsonEncode(embeddings)));
    }

    if (photos != null) {
      for (var i = 0; i < photos.length; i++) {
        formData.files.add(MapEntry(
          'photos[]',
          MultipartFile.fromBytes(
            photos[i],
            filename: 'face_$i.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        ));
      }
    }

    final response = await dio.post(
      ApiConstants.faceEnroll,
      data: formData,
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> verify({required Uint8List photo}) async {
    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(
        photo,
        filename: 'verify_face.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    final response = await dio.post(ApiConstants.faceVerify, data: formData);

    final data = response.data as Map<String, dynamic>;
    return data['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['data'])
        : data;
  }

  @override
  Future<List<double>?> downloadTemplate() async {
    final response = await dio.get(ApiConstants.faceTemplate);

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final embedding = data['embedding'];
        if (embedding != null) {
          return (embedding as List).map((e) => (e as num).toDouble()).toList();
        }
      }
    }

    return null;
  }

  @override
  Future<Map<String, dynamic>> deleteFace() async {
    final response = await dio.delete(ApiConstants.faceDelete);

    final data = response.data as Map<String, dynamic>;
    return data['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['data'])
        : data;
  }
}

