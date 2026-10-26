import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';

// SharedPreferences untuk data kritis (auth token, user session)
// — lebih reliable di device tertentu (TECNO/Transsion)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnsupportedError('SharedPreferences must be initialized before accessing. Check main.dart');
});

// FlutterSecureStorage untuk data non-kritis (device uid, security flags)
final flutterSecureStorageProvider =
    Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dio = Dio();
  DioClient(dio: dio, prefs: prefs);
  return dio;
});
