import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nhai_app/api/models/user.dart';
import '../api/auth_api.dart';

class AuthService {
  final AuthAPI _authAPI;
  final FlutterSecureStorage _secureStorage;

  AuthService(this._authAPI, this._secureStorage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<User?> login(String username, String password) async {
    try {
      final user = await _authAPI.login(username, password);
      await _secureStorage.write(key: _accessTokenKey, value: user.accessToken);
      await _secureStorage.write(
          key: _refreshTokenKey, value: user.refreshToken);

      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<User?> initializeSession() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final user = await _authAPI.refreshAccessToken(refreshToken);
      await _secureStorage.write(key: _accessTokenKey, value: user.accessToken);

      return user;
    } catch (e) {
      await logout();
      return null;
    }
  }

  Future<void> registerAdmin(String username, String password) async {
    try {
      await _authAPI.registerAdmin(username, password);
    } catch (e) {
      rethrow;
    }
  }
}
