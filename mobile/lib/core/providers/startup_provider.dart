import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

enum StartupDestination { home, login, onboarding }

/// Single source of truth untuk menentukan tujuan awal aplikasi.
/// Logika:
///   1. onboarding belum selesai  → onboarding
///   2. tidak ada token           → login
///   3. ada token, valid          → home
///   4. ada token, invalid (401)  → logout + login
///   5. ada token, offline         → home (offline mode)
final startupDestinationProvider =
    FutureProvider<StartupDestination>((ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final authRepo = ref.read(authRepositoryProvider);

  final onboardingDone =
      prefs.getBool(StorageKeys.onboardingSeen) ?? false;
  if (!onboardingDone) return StartupDestination.onboarding;

  final token = prefs.getString(StorageKeys.accessToken);
  final user = prefs.getString(StorageKeys.user);
  if (token == null || token.isEmpty || user == null || user.isEmpty) {
    return StartupDestination.login;
  }

  final result = await authRepo.validateToken();
  switch (result) {
    case TokenValidationResult.valid:
      return StartupDestination.home;
    case TokenValidationResult.invalid:
      await authRepo.logout();
      return StartupDestination.login;
    case TokenValidationResult.offline:
      return StartupDestination.home;
  }
});
