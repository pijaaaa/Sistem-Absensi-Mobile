import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

class DioClient {
  final Dio dio;
  final FlutterSecureStorage storage;

  DioClient({
    required this.dio,
    required this.storage,
  }) {
    dio.options.baseUrl = ApiConstants.baseUrl;
    dio.options.connectTimeout = ApiConstants.connectTimeout;
    dio.options.receiveTimeout = ApiConstants.receiveTimeout;
    dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    dio.interceptors.addAll([
      _AuthInterceptor(storage, dio),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio dio;

  _AuthInterceptor(this.storage, this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid
      await storage.delete(key: 'access_token');
      // Could navigate to login here if needed
    }
    handler.next(err);
  }
}
