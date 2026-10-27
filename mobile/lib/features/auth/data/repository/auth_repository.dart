import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/features/auth/data/datasource/auth_data_source.dart';

enum TokenValidationResult { valid, invalid, offline }

class AuthRepository {
  final AuthDataSource dataSource;

  AuthRepository({required this.dataSource});

  Future<UserModel> login({
    required String login,
    required String password,
  }) async {
    await dataSource.login(login: login, password: password);
    final user = await dataSource.fetchMe();

    // Menu & permission dimuat di Home, bukan di login — 
    // bila gagal, login tetap berhasil
    try {
      await dataSource.fetchMenus();
    } catch (e) {
      debugPrint('[AUTH] login fetchMenus ignored: $e');
    }
    try {
      await dataSource.fetchPermissions();
    } catch (e) {
      debugPrint('[AUTH] login fetchPermissions ignored: $e');
    }

    // Register FCM token with backend after successful login
    final fcm = FirebaseMessaging.instance;
    final token = await fcm.getToken();
    if (token != null) {
      await dataSource.updateFcmToken(token);
    }

    return user;
  }

  Future<void> logout() async {
    await dataSource.logout();
  }

  Future<UserModel?> getCurrentUser() async {
    return await dataSource.getUser();
  }

  Future<String?> getToken() async {
    return await dataSource.getToken();
  }

  Future<List<Map<String, dynamic>>> getMenus() async {
    return await dataSource.fetchMenus();
  }

  Future<Set<String>> getPermissions() async {
    return await dataSource.fetchPermissions();
  }

  Future<void> updateFcmToken(String token) async {
    await dataSource.updateFcmToken(token);
  }

  Future<void> saveUserLocally(UserModel user) async {
    await dataSource.saveUser(user);
  }

  Future<bool> hasUserLocally() async {
    final user = await dataSource.getUser();
    return user != null;
  }

  Future<bool> hasOnboardingDone() async {
    return await dataSource.hasOnboardingDone();
  }

  Future<TokenValidationResult> validateToken() async {
    try {
      await dataSource.fetchMe();
      return TokenValidationResult.valid;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return TokenValidationResult.invalid;
      }
      return TokenValidationResult.offline;
    } catch (e) {
      // fetchMe may wrap DioException as Exception — periksa apakah token
      // sudah dihapus oleh interceptor (race condition)
      final token = await dataSource.getToken();
      if (token == null || token.isEmpty) {
        return TokenValidationResult.invalid;
      }
      return TokenValidationResult.offline;
    }
  }
}
