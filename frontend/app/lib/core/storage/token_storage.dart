import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_role';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
  }) async {
    await _storage.write(
      key: _accessTokenKey,
      value: accessToken,
    );

    await _storage.write(
      key: _refreshTokenKey,
      value: refreshToken,
    );

    if (role != null && role.isNotEmpty) {
      await _storage.write(
        key: _userRoleKey,
        value: role.toUpperCase(),
      );
    }
  }

  static Future<void> saveUserRole(String role) async {
    await _storage.write(
      key: _userRoleKey,
      value: role.toUpperCase(),
    );
  }

  static Future<String?> getUserRole() {
    return _storage.read(
      key: _userRoleKey,
    );
  }

  static Future<String?> getAccessToken() {
    return _storage.read(
      key: _accessTokenKey,
    );
  }

  static Future<String?> getRefreshToken() {
    return _storage.read(
      key: _refreshTokenKey,
    );
  }

  static Future<void> clear() async {
    await _storage.delete(
      key: _accessTokenKey,
    );

    await _storage.delete(
      key: _refreshTokenKey,
    );

    await _storage.delete(
      key: _userRoleKey,
    );
  }
}
