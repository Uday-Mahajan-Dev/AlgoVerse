import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../auth/data/social_auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await ApiClient.logout(refreshToken);
        } catch (_) {
          // Even if the server logout fails, clear local credentials.
        }
      }

      // Sign out of Firebase/Google/GitHub if a social login was used.
      try {
        await SocialAuthService.signOut();
      } catch (_) {
        // Ignore social sign-out errors.
      }

      await TokenStorage.clear();

      if (!mounted) return;

      context.go(AppRoutes.login);
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AlgoVerse'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Welcome to AlgoVerse'),

            const SizedBox(height: AppSpacing.lg),

            const AppCard(
              child: Text('Your adaptive DSA learning journey starts here.'),
            ),

            const SizedBox(height: AppSpacing.lg),

            PrimaryButton(text: 'Start Learning', onPressed: () {}),

            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isLoggingOut ? null : _logout,
                icon: const Icon(Icons.logout),
                label: Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
