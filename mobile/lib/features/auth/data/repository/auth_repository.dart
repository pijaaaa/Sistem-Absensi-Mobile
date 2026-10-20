import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/features/auth/data/datasource/auth_data_source.dart';

class AuthRepository {
  final AuthDataSource dataSource;

  AuthRepository({required this.dataSource});

  Future<UserModel> login({
    required String login,
    required String password,
  }) async {
    await dataSource.login(login: login, password: password);
    final user = await dataSource.fetchMe();
    await dataSource.fetchMenus();
    await dataSource.fetchPermissions();
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
    // Will implement later when FCM is set up
  }

  Future<void> saveUserLocally(UserModel user) async {
    await dataSource.saveUser(user);
  }

  Future<bool> hasUserLocally() async {
    final user = await dataSource.getUser();
    return user != null;
  }
}
