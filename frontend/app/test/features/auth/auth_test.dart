import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algoverse/core/storage/token_storage.dart';
import 'package:algoverse/features/auth/presentation/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await TokenStorage.clear();
  });

  group('TokenStorage unit tests', () {
    test('saveTokens and getAccessToken retrieves persisted tokens', () async {
      await TokenStorage.saveTokens(
        accessToken: 'test_access_jwt',
        refreshToken: 'test_refresh_jwt',
        role: 'TEACHER',
        userId: 'user_123',
        email: 'teacher@algoverse.dev',
        name: 'Prof. Algorithm',
      );

      final token = await TokenStorage.getAccessToken();
      final refreshToken = await TokenStorage.getRefreshToken();
      final role = await TokenStorage.getUserRole();
      final userId = await TokenStorage.getUserId();
      final email = await TokenStorage.getUserEmail();
      final name = await TokenStorage.getUserName();

      expect(token, 'test_access_jwt');
      expect(refreshToken, 'test_refresh_jwt');
      expect(role, 'TEACHER');
      expect(userId, 'user_123');
      expect(email, 'teacher@algoverse.dev');
      expect(name, 'Prof. Algorithm');
      expect(await TokenStorage.hasToken(), isTrue);
    });

    test('clear wipes all stored token data', () async {
      await TokenStorage.saveTokens(
        accessToken: 'test_access_jwt',
        refreshToken: 'test_refresh_jwt',
        role: 'STUDENT',
      );

      await TokenStorage.clear();

      expect(await TokenStorage.getAccessToken(), isNull);
      expect(await TokenStorage.getRefreshToken(), isNull);
      expect(await TokenStorage.getUserRole(), isNull);
      expect(await TokenStorage.hasToken(), isFalse);
    });
  });

  group('AuthState unit tests', () {
    test('initial state is unauthenticated or initial', () {
      const state = AuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.isAuthenticated, isFalse);
    });

    test('authenticated state with valid token returns isAuthenticated true', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        accessToken: 'valid_jwt_token',
        role: 'STUDENT',
      );
      expect(state.isAuthenticated, isTrue);
    });

    test('unauthenticated status returns isAuthenticated false', () {
      const state = AuthState(
        status: AuthStatus.unauthenticated,
        accessToken: null,
      );
      expect(state.isAuthenticated, isFalse);
    });
  });

  group('AuthNotifier & Riverpod Container', () {
    test('restoreSession returns false when no token exists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      final restored = await notifier.restoreSession();

      expect(restored, isFalse);
      expect(container.read(authStateProvider).status, AuthStatus.unauthenticated);
      expect(container.read(authStateProvider).isAuthenticated, isFalse);
    });

    test('handleSessionExpired sets state to unauthenticated with clear message', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      await notifier.handleSessionExpired();

      final state = container.read(authStateProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, contains('Session expired'));
    });
  });
}

