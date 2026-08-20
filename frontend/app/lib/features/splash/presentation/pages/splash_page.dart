import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final accessToken = await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      _goToLogin();
      return;
    }

    try {
      final user = await ApiClient.me(accessToken);
      final role = user['role_name']?.toString();

      if (role != null) {
        await TokenStorage.saveUserRole(role);
      }

      if (!mounted) return;

      if (role == 'TEACHER') {
        context.go(AppRoutes.teacher);
      } else {
        context.go(AppRoutes.home);
      }
    } catch (_) {
      await TokenStorage.clear();

      if (!mounted) return;

      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;

    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'AlgoVerse',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Learn • Visualize • Conquer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 32),

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
