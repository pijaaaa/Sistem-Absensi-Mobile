import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/network/dio_client.dart';

final flutterSecureStorageProvider =
    Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final storage = ref.watch(flutterSecureStorageProvider);
  DioClient(dio: dio, storage: storage);
  return dio;
});
