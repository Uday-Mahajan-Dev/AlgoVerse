import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  // In-memory cache for fast synchronous & optimistic reads
  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;
  static String? _cachedUserRole;
  static String? _cachedUserId;
  static String? _cachedUserEmail;
  static String? _cachedUserName;

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
    String? userId,
    String? email,
    String? name,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    if (role != null && role.isNotEmpty) _cachedUserRole = role.toUpperCase();
    if (userId != null && userId.isNotEmpty) _cachedUserId = userId;
    if (email != null && email.isNotEmpty) _cachedUserEmail = email;
    if (name != null && name.isNotEmpty) _cachedUserName = name;

    try {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      if (role != null && role.isNotEmpty) {
        await _secureStorage.write(key: _userRoleKey, value: role.toUpperCase());
      }
      if (userId != null && userId.isNotEmpty) {
        await _secureStorage.write(key: _userIdKey, value: userId);
      }
      if (email != null && email.isNotEmpty) {
        await _secureStorage.write(key: _userEmailKey, value: email);
      }
      if (name != null && name.isNotEmpty) {
        await _secureStorage.write(key: _userNameKey, value: name);
      }
    } catch (e) {
      debugPrint('[TokenStorage] Error writing to SecureStorage: $e');
    }

    // Also persist non-sensitive / backup flags in SharedPreferences for cold-start reliability
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      if (role != null && role.isNotEmpty) {
        await prefs.setString(_userRoleKey, role.toUpperCase());
      }
      if (userId != null && userId.isNotEmpty) {
        await prefs.setString(_userIdKey, userId);
      }
      if (email != null && email.isNotEmpty) {
        await prefs.setString(_userEmailKey, email);
      }
      if (name != null && name.isNotEmpty) {
        await prefs.setString(_userNameKey, name);
      }
    } catch (e) {
      debugPrint('[TokenStorage] Error writing to SharedPreferences: $e');
    }
  }

  static Future<void> saveUserRole(String role) async {
    final upperRole = role.toUpperCase();
    _cachedUserRole = upperRole;

    try {
      await _secureStorage.write(key: _userRoleKey, value: upperRole);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, upperRole);
    } catch (_) {}
  }

  static Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken;
    }

    try {
      final token = await _secureStorage.read(key: _accessTokenKey);
      if (token != null && token.isNotEmpty) {
        _cachedAccessToken = token;
        return token;
      }
    } catch (e) {
      debugPrint('[TokenStorage] SecureStorage read access_token error: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);
      if (token != null && token.isNotEmpty) {
        _cachedAccessToken = token;
        return token;
      }
    } catch (_) {}

    return null;
  }

  static Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      return _cachedRefreshToken;
    }

    try {
      final token = await _secureStorage.read(key: _refreshTokenKey);
      if (token != null && token.isNotEmpty) {
        _cachedRefreshToken = token;
        return token;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_refreshTokenKey);
      if (token != null && token.isNotEmpty) {
        _cachedRefreshToken = token;
        return token;
      }
    } catch (_) {}

    return null;
  }

  static Future<String?> getUserRole() async {
    if (_cachedUserRole != null && _cachedUserRole!.isNotEmpty) {
      return _cachedUserRole;
    }

    try {
      final role = await _secureStorage.read(key: _userRoleKey);
      if (role != null && role.isNotEmpty) {
        _cachedUserRole = role.toUpperCase();
        return _cachedUserRole;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(_userRoleKey);
      if (role != null && role.isNotEmpty) {
        _cachedUserRole = role.toUpperCase();
        return _cachedUserRole;
      }
    } catch (_) {}

    return null;
  }

  static Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    try {
      final id = await _secureStorage.read(key: _userIdKey);
      if (id != null && id.isNotEmpty) {
        _cachedUserId = id;
        return id;
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_userIdKey);
      if (id != null && id.isNotEmpty) {
        _cachedUserId = id;
        return id;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> getUserEmail() async {
    if (_cachedUserEmail != null) return _cachedUserEmail;
    try {
      final email = await _secureStorage.read(key: _userEmailKey);
      if (email != null && email.isNotEmpty) {
        _cachedUserEmail = email;
        return email;
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_userEmailKey);
      if (email != null && email.isNotEmpty) {
        _cachedUserEmail = email;
        return email;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> getUserName() async {
    if (_cachedUserName != null) return _cachedUserName;
    try {
      final name = await _secureStorage.read(key: _userNameKey);
      if (name != null && name.isNotEmpty) {
        _cachedUserName = name;
        return name;
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_userNameKey);
      if (name != null && name.isNotEmpty) {
        _cachedUserName = name;
        return name;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clear() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUserRole = null;
    _cachedUserId = null;
    _cachedUserEmail = null;
    _cachedUserName = null;

    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userRoleKey);
      await _secureStorage.delete(key: _userIdKey);
      await _secureStorage.delete(key: _userEmailKey);
      await _secureStorage.delete(key: _userNameKey);
    } catch (e) {
      debugPrint('[TokenStorage] Error clearing SecureStorage: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userRoleKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);
    } catch (e) {
      debugPrint('[TokenStorage] Error clearing SharedPreferences: $e');
    }
  }
}
