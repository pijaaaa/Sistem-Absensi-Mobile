import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  final bool splashDone;
  final bool isLoggedIn;
  final bool onboardingDone;

  const AppState({
    this.splashDone = false,
    this.isLoggedIn = false,
    this.onboardingDone = false,
  });

  AppState copyWith({
    bool? splashDone,
    bool? isLoggedIn,
    bool? onboardingDone,
  }) {
    return AppState(
      splashDone: splashDone ?? this.splashDone,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref? ref;
  final SharedPreferences? prefs;

  AppStateNotifier([this.ref, this.prefs]) : super(const AppState());

  AppStateNotifier.withInitialState({
    required SharedPreferences prefsInstance,
    required bool isLoggedIn,
    required bool onboardingDone,
  })  : ref = null,
        prefs = prefsInstance,
        super(AppState(
          isLoggedIn: isLoggedIn,
          onboardingDone: onboardingDone,
        ));

  SharedPreferences _getPrefs() {
    if (prefs != null) return prefs!;
    if (ref != null) return ref!.read(sharedPreferencesProvider);
    throw StateError('Neither prefs nor ref is available in AppStateNotifier');
  }

  Future<void> initialize() async {
    final p = _getPrefs();
    final token = p.getString(StorageKeys.accessToken);
    final onboardingDone = p.getBool(StorageKeys.onboardingSeen) ?? false;

    state = state.copyWith(
      isLoggedIn: token != null && token.isNotEmpty,
      onboardingDone: onboardingDone,
    );
  }

  void finishSplash() {
    if (state.splashDone) return;
    state = state.copyWith(splashDone: true);
  }

  Future<void> completeOnboarding() async {
    final p = _getPrefs();
    await p.setBool(StorageKeys.onboardingSeen, true);
    state = state.copyWith(onboardingDone: true);
  }

  Future<void> loginSuccess(String token) async {
    state = state.copyWith(isLoggedIn: true);
  }

  Future<void> logout() async {
    final p = _getPrefs();
    await p.remove(StorageKeys.accessToken);
    await p.remove(StorageKeys.user);
    await p.remove(StorageKeys.menus);
    await p.remove(StorageKeys.permissions);
    state = state.copyWith(isLoggedIn: false);
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(ref);
});
