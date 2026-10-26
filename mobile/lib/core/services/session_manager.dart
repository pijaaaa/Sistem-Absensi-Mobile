import 'package:mobile/core/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static VoidVoidCallback? onSessionExpired;
  static SharedPreferences? _prefs;

  static void setPrefs(SharedPreferences prefs) {
    _prefs = prefs;
  }

  static Future<void> clearAuthData() async {
    try {
      await _prefs?.remove(StorageKeys.accessToken);
      await _prefs?.remove(StorageKeys.user);
      await _prefs?.remove(StorageKeys.menus);
      await _prefs?.remove(StorageKeys.permissions);
    } catch (e) {
      // ignore
    }
  }

  static void triggerLogout() {
    onSessionExpired?.call();
  }
}

typedef VoidVoidCallback = void Function();
