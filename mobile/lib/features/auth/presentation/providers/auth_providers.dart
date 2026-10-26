import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/services/security_service.dart';
import 'package:mobile/features/auth/data/datasource/auth_data_source.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/core/network/providers.dart';
import 'package:mobile/features/auth/presentation/providers/device_providers.dart';

final authLoadingProvider = StateProvider<bool>((ref) => false);

// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return AuthRepository(dataSource: dataSource);
});

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final deviceService = ref.watch(deviceServiceProvider);
  return AuthDataSourceImpl(dio: dio, prefs: prefs, deviceService: deviceService);
});

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final UserModel? user;
  final EmployeeModel? employee;
  final List<Map<String, dynamic>> menus;
  final Set<String> permissions;
  final bool isLoadingMenus;

  AuthState({
    this.isAuthenticated = false,
    this.token,
    this.user,
    this.employee,
    this.menus = const [],
    this.permissions = const {},
    this.isLoadingMenus = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    UserModel? user,
    EmployeeModel? employee,
    List<Map<String, dynamic>>? menus,
    Set<String>? permissions,
    bool? isLoadingMenus,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      user: user ?? this.user,
      employee: employee ?? this.employee,
      menus: menus ?? this.menus,
      permissions: permissions ?? this.permissions,
      isLoadingMenus: isLoadingMenus ?? this.isLoadingMenus,
    );
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState());

  void setAuthenticated({
    required String token,
    required UserModel user,
    EmployeeModel? employee,
    required List<Map<String, dynamic>> menus,
    required Set<String> permissions,
  }) {
    state = state.copyWith(
      isAuthenticated: true,
      token: token,
      user: user,
      employee: employee ?? user.employee,
      menus: menus,
      permissions: permissions,
    );
  }

  void setMenus(List<Map<String, dynamic>> menus) {
    state = state.copyWith(menus: menus);
  }

  void setPermissions(Set<String> permissions) {
    state = state.copyWith(permissions: permissions);
  }

  /// Refresh auth state from API
  Future<void> refreshAuthState() async {
    debugPrint('[AUTH] refreshAuthState: START');
    try {
      final authRepo = ref.read(authRepositoryProvider);

      debugPrint('[AUTH] refreshAuthState: reading token+user from storage');
      final token = await authRepo.getToken();
      final user = await authRepo.getCurrentUser();
      final displayToken = token != null && token.length > 10
          ? '${token.substring(0, 10)}...'
          : token ?? 'null';
      debugPrint('[AUTH] token: $displayToken');
      debugPrint('[AUTH] user: ${user?.name ?? 'null'}');

      if (token == null || token.isEmpty || user == null) {
        debugPrint('[AUTH] no token/user found, setting isAuthenticated=false');
        state = state.copyWith(
          isAuthenticated: false,
          token: null,
          user: null,
          employee: null,
          menus: [],
          permissions: {},
        );
        debugPrint('[AUTH] refreshAuthState: DONE (no token)');
        return;
      }

      // Validate token against backend (distinguish 401 vs offline)
      debugPrint('[AUTH] validating token against backend');
      final result = await authRepo.validateToken();
      debugPrint('[AUTH] validateToken result: $result');
      if (result == TokenValidationResult.invalid) {
        debugPrint('[AUTH] token invalid/expired, clearing auth state');
        await authRepo.logout();
        state = state.copyWith(
          isAuthenticated: false,
          token: null,
          user: null,
          employee: null,
          menus: [],
          permissions: {},
        );
        debugPrint('[AUTH] refreshAuthState: DONE (invalid token)');
        return;
      }

      if (result == TokenValidationResult.offline) {
        debugPrint('[AUTH] offline with token — allowing offline access');
      } else {
        debugPrint('[AUTH] token valid, setting isAuthenticated=true');
      }

      state = state.copyWith(
        isAuthenticated: true,
        token: token,
        user: user,
        employee: user.employee,
      );

      try {
        final menus = await authRepo.getMenus();
        state = state.copyWith(menus: menus);
      } catch (e) {
        debugPrint('[AUTH] getMenus error: $e');
      }

      try {
        final permissions = await authRepo.getPermissions();
        state = state.copyWith(permissions: permissions);
      } catch (e) {
        debugPrint('[AUTH] getPermissions error: $e');
      }

      Future.microtask(
        ref.read(securityServiceWithDioProvider).reportSecurityFlags,
      );
    } catch (e) {
      debugPrint('[AUTH] refreshAuthState error: $e');
      state = state.copyWith(
        isAuthenticated: false,
        token: null,
        user: null,
        employee: null,
        menus: [],
        permissions: {},
      );
    }
  }

  Future<void> logout() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.logout();
    state = AuthState();
  }

  void setLoadingMenus(bool isLoading) {
    state = state.copyWith(isLoadingMenus: isLoading);
  }
}

final currentMenusProvider = Provider<List<Map<String, dynamic>>?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.menus;
});

final currentPermissionsProvider = Provider<Set<String>>((ref) {
  return ref.watch(authStateProvider.select((s) => s.permissions));
});

final canProvider = Provider.family<bool, String>((ref, permissionKey) {
  final permissions = ref.watch(currentPermissionsProvider);
  return permissions.contains(permissionKey);
});
