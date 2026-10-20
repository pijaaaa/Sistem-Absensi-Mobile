import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

class ThemeSettings {
  static const String keyThemeMode = 'theme_mode';
  static const String themeSystem = 'system';
  static const String themeLight = 'light';
  static const String themeDark = 'dark';

  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(keyThemeMode) ?? themeSystem;
    switch (saved) {
      case themeLight:
        return ThemeMode.light;
      case themeDark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = themeLight;
        break;
      case ThemeMode.dark:
        value = themeDark;
        break;
      default:
        value = themeSystem;
    }
    await prefs.setString(keyThemeMode, value);
  }

  static ThemeMode cycle(ThemeMode current) {
    switch (current) {
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}

final savedThemeModeProvider = FutureProvider<ThemeMode>((ref) async {
  return ThemeSettings.loadThemeMode();
});

class ThemeManager {
  static void toggleTheme(WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    final next = ThemeSettings.cycle(current);
    ref.read(themeModeProvider.notifier).state = next;
    ThemeSettings.saveThemeMode(next);
  }
}
