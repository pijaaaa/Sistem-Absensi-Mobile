import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/services/device_service.dart';
import 'package:mobile/core/constants/api_constants.dart';

abstract class AuthDataSource {
  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  });
  Future<UserModel> fetchMe();
  Future<List<Map<String, dynamic>>> fetchMenus();
  Future<Set<String>> fetchPermissions();
  Future<void> updateFcmToken(String token);
  Future<void> saveToken(String token);
  Future<void> saveUser(UserModel user);
  Future<String?> getToken();
  Future<UserModel?> getUser();
  Future<bool> hasOnboardingDone();
  Future<void> logout();
}

class AuthDataSourceImpl implements AuthDataSource {
  final Dio dio;
  final SharedPreferences prefs;
  final DeviceService deviceService;

  AuthDataSourceImpl({required this.dio, required this.prefs, required this.deviceService});

  @override
  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    final deviceUid = await deviceService.getDeviceUid();
    final deviceName = await deviceService.getDeviceName();

    Response response;
    try {
      response = await dio.post(
        ApiConstants.login,
        data: {
          'login': login,
          'password': password,
          'device_uid': deviceUid,
          'device_name': deviceName,
        },
      );
    } on DioException catch (e) {
      debugPrint('[AUTH] Login error: ${e.message}');
      debugPrint('[AUTH] Login error type: ${e.type}');
      debugPrint('[AUTH] Login error response: ${e.response?.data}');
      debugPrint('[AUTH] Login error status: ${e.response?.statusCode}');
      throw Exception(_formatError(e));
    }

    final data = response.data as Map<String, dynamic>;
    final apiData = data['data'] as Map<String, dynamic>? ?? data;
    final token = apiData['token'] ?? apiData['access_token'] ?? '';
    await saveToken(token);

    if (apiData['user'] != null) {
      final user = UserModel.fromJson(apiData['user']);
      await saveUser(user);
    }

    return data;
  }

  @override
  Future<UserModel> fetchMe() async {
    try {
      final response = await dio.get(ApiConstants.me);
      final data = response.data as Map<String, dynamic>;
      final apiData = data['data'] as Map<String, dynamic>? ?? data;
      final user = UserModel.fromJson(apiData);
      await saveUser(user);
      return user;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMenus() async {
    try {
      final response = await dio.get(ApiConstants.menus);
      final data = response.data as Map<String, dynamic>;
      final menus = (data['data'] as List? ?? data['menus'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      await prefs.setString(StorageKeys.menus, _encodeList(menus));
      return menus;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  @override
  Future<Set<String>> fetchPermissions() async {
    try {
      final response = await dio.get(ApiConstants.permissions);
      final data = response.data as Map<String, dynamic>;
      // Backend returns: { "data": { "is_superadmin": bool, "keys": ["perm1", "perm2"] } }
      final permissionData = data['data'] as Map<String, dynamic>? ?? data;
      final permissions = (permissionData['keys'] as List? ?? permissionData['permissions'] as List? ?? [])
          .map((e) => e as String)
          .toSet();
      await prefs.setString(
          StorageKeys.permissions, permissions.join(','));
      return permissions;
    } on DioException catch (e) {
      throw Exception(_formatError(e));
    }
  }

  @override
  Future<void> updateFcmToken(String token) async {
    try {
      await dio.post(
        ApiConstants.fcmToken,
        data: {'token': token},
      );
    } on DioException catch (e) {
      debugPrint('[AUTH] FCM token update error: ${e.message}');
    }
  }

  @override
  Future<void> saveToken(String token) async {
    await prefs.setString(StorageKeys.accessToken, token);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await prefs.setString(StorageKeys.user, _encodeUser(user));
  }

  @override
  Future<String?> getToken() async {
    return prefs.getString(StorageKeys.accessToken);
  }

  @override
  Future<UserModel?> getUser() async {
    final data = prefs.getString(StorageKeys.user);
    if (data == null || data.isEmpty) return null;
    try {
      final json = _decodeUser(data);
      return UserModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> hasOnboardingDone() async {
    return prefs.getBool(StorageKeys.onboardingSeen) ?? false;
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post(ApiConstants.logout);
    } catch (_) {
      // Ignore network errors on logout
    }
    await prefs.remove(StorageKeys.accessToken);
    await prefs.remove(StorageKeys.user);
    await prefs.remove(StorageKeys.menus);
    await prefs.remove(StorageKeys.permissions);
  }

  String _formatError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (e.response?.statusCode == 401) return 'NIP/email atau password salah.';
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Pastikan jaringan Anda menyala.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  String _encodeUser(UserModel user) {
    return jsonEncode(user.toJson());
  }

  Map<String, dynamic> _decodeUser(String data) {
    return jsonDecode(data) as Map<String, dynamic>;
  }

  String _encodeList(List<Map<String, dynamic>> list) {
    return jsonEncode(list);
  }
}
