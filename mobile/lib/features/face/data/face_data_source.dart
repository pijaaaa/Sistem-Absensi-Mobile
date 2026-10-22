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
}

