import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

class DioClient {
  final Dio dio;
  final SharedPreferences prefs;

  DioClient({
    required this.dio,
    required this.prefs,
  }) {
    dio.options.baseUrl = ApiConstants.baseUrl;
    dio.options.connectTimeout = ApiConstants.connectTimeout;
    dio.options.receiveTimeout = ApiConstants.receiveTimeout;
    dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    dio.interceptors.addAll([
      _AuthInterceptor(prefs, dio),
    ]);
  }
}

class _AuthInterceptor extends Interceptor {
  final SharedPreferences prefs;
  final Dio dio;

  _AuthInterceptor(this.prefs, this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = prefs.getString('access_token');
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
      debugPrint('[DIO] 401 Unauthorized — token may be expired');
      final path = err.requestOptions.path;
      if (!path.contains('/auth/login') && !path.contains('/auth/logout')) {
        await prefs.remove('access_token');
        await prefs.remove('user_data');
      }
    }
    handler.next(err);
  }
}
