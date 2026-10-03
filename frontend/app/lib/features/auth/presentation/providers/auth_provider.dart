import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/social_auth_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final String? role;
  final String? userId;
  final String? email;
  final String? name;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.accessToken,
    this.refreshToken,
    this.role,
    this.userId,
    this.email,
    this.name,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated &&
      accessToken != null &&
      accessToken!.isNotEmpty;

  AuthState copyWith({
    AuthStatus? status,
    String? accessToken,
    String? refreshToken,
    String? role,
    String? userId,
    String? email,
    String? name,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// A ChangeNotifier that bridges Riverpod AuthState to GoRouter's refreshListenable.
class AuthListenable extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

final authListenableProvider = Provider<AuthListenable>((ref) {
  return AuthListenable();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Hook into global API 401 callback
    ApiClient.onUnauthorizedSession = handleSessionExpired;
    return const AuthState();
  }

  /// Restores session on app startup (cold start / swipe-away reopen).
  /// Optimistically validates stored tokens and keeps session alive even if offline.
  Future<bool> restoreSession() async {
    try {
      final token = await TokenStorage.getAccessToken();
      final refreshToken = await TokenStorage.getRefreshToken();
      final role = await TokenStorage.getUserRole();
      final userId = await TokenStorage.getUserId();
      final email = await TokenStorage.getUserEmail();
      final name = await TokenStorage.getUserName();

      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        ref.read(authListenableProvider).notify();
        return false;
      }

      // Optimistically mark as authenticated with stored metadata
      state = AuthState(
        status: AuthStatus.authenticated,
        accessToken: token,
        refreshToken: refreshToken,
        role: role ?? 'STUDENT',
        userId: userId,
        email: email,
        name: name,
      );
      ref.read(authListenableProvider).notify();

      // Verify token in background with /me
      try {
        final userData = await ApiClient.me(token);
        final freshRole = (userData['role_name']?.toString() ??
                userData['role']?.toString() ??
                role ??
                'STUDENT')
            .toUpperCase();
        final freshEmail = userData['email']?.toString() ?? email;
        final firstName = userData['first_name']?.toString() ?? '';
        final lastName = userData['last_name']?.toString() ?? '';
        final freshName = ('$firstName $lastName').trim().isNotEmpty
            ? ('$firstName $lastName').trim()
            : (userData['username']?.toString() ?? name);
        final freshUserId = userData['id']?.toString() ?? userId;

        await TokenStorage.saveTokens(
          accessToken: token,
          refreshToken: refreshToken ?? '',
          role: freshRole,
          userId: freshUserId,
          email: freshEmail,
          name: freshName,
        );

        state = state.copyWith(
          role: freshRole,
          email: freshEmail,
          name: freshName,
          userId: freshUserId,
        );
        ref.read(authListenableProvider).notify();
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        // Only if token was explicitly rejected with 401 do we invalidate the session
        if (errStr.contains('401') ||
            errStr.contains('session expired') ||
            errStr.contains('unauthorized')) {
          await TokenStorage.clear();
          state = const AuthState(status: AuthStatus.unauthenticated);
          ref.read(authListenableProvider).notify();
          return false;
        }
        // Network timeout / offline / connection errors keep the user authenticated!
        debugPrint(
            '[AuthNotifier] /me network error on restore, keeping cached session: $e');
      }

      return true;
    } catch (e) {
      debugPrint('[AuthNotifier] Error during session restoration: $e');
      state = const AuthState(status: AuthStatus.unauthenticated);
      ref.read(authListenableProvider).notify();
      return false;
    }
  }

  /// Email & password login.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final tokens = await ApiClient.login(email: email, password: password);
      final accessToken = tokens['access_token']?.toString() ?? '';
      final refreshToken = tokens['refresh_token']?.toString() ?? '';

      if (accessToken.isEmpty) {
        throw Exception('Invalid token response from server.');
      }

      String role = 'STUDENT';
      String? userId;
      String? userEmail = email;
      String? userName;

      try {
        final userData = await ApiClient.me(accessToken);
        role = (userData['role_name']?.toString() ??
                userData['role']?.toString() ??
                'STUDENT')
            .toUpperCase();
        userEmail = userData['email']?.toString() ?? email;
        final firstName = userData['first_name']?.toString() ?? '';
        final lastName = userData['last_name']?.toString() ?? '';
        userName = ('$firstName $lastName').trim().isNotEmpty
            ? ('$firstName $lastName').trim()
            : (userData['username']?.toString() ?? '');
        userId = userData['id']?.toString();
      } catch (_) {}

      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: role,
        userId: userId,
        email: userEmail,
        name: userName,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: role,
        userId: userId,
        email: userEmail,
        name: userName,
        isLoading: false,
      );
      ref.read(authListenableProvider).notify();

      return role;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  /// Social Login (Google / GitHub) JWT exchange.
  Future<String> socialLogin(
    Future<Map<String, dynamic>> Function() loginMethod,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final tokens = await loginMethod();
      final accessToken = tokens['access_token']?.toString() ?? '';
      final refreshToken = tokens['refresh_token']?.toString() ?? '';

      if (accessToken.isEmpty) {
        throw Exception('Invalid token response from server.');
      }

      String role = 'STUDENT';
      String? userId;
      String? userEmail;
      String? userName;

      try {
        final userData = await ApiClient.me(accessToken);
        role = (userData['role_name']?.toString() ??
                userData['role']?.toString() ??
                'STUDENT')
            .toUpperCase();
        userEmail = userData['email']?.toString();
        final firstName = userData['first_name']?.toString() ?? '';
        final lastName = userData['last_name']?.toString() ?? '';
        userName = ('$firstName $lastName').trim().isNotEmpty
            ? ('$firstName $lastName').trim()
            : (userData['username']?.toString() ?? '');
        userId = userData['id']?.toString();
      } catch (_) {}

      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: role,
        userId: userId,
        email: userEmail,
        name: userName,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: role,
        userId: userId,
        email: userEmail,
        name: userName,
        isLoading: false,
      );
      ref.read(authListenableProvider).notify();

      return role;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  /// Global Logout:
  /// 1. Invalidate server-side refresh token (non-blocking)
  /// 2. Disconnect Google / Firebase session
  /// 3. Clear all stored auth keys
  /// 4. Reset Riverpod AuthState to unauthenticated
  /// 5. Hard redirect to login screen
  Future<void> logout({BuildContext? context}) async {
    final refreshToken =
        state.refreshToken ?? await TokenStorage.getRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await ApiClient.logout(refreshToken);
      } catch (_) {}
    }

    try {
      await SocialAuthService.signOut();
    } catch (_) {}

    await TokenStorage.clear();

    state = const AuthState(status: AuthStatus.unauthenticated);
    ref.read(authListenableProvider).notify();

    if (context != null && context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  /// Handles 401 session expiration from API calls.
  Future<void> handleSessionExpired() async {
    if (state.status == AuthStatus.unauthenticated) return;

    await TokenStorage.clear();
    if (!ref.mounted) return;
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Session expired. Please log in again.',
    );
    ref.read(authListenableProvider).notify();
  }
}

final authStateProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final authNotifierProvider = authStateProvider;

