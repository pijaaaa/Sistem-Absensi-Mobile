import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/models/user_model.dart';

final authLoadingProvider = StateProvider<bool>((ref) => false);

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
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

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

  void logout() {
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
