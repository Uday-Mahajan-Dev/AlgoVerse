import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/social_login_button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),

              const FlutterLogo(size: 100),

              const SizedBox(height: AppSpacing.xl),

              Text("AlgoVerse", style: AppTypography.heading1),

              const SizedBox(height: AppSpacing.sm),

              Text("Learn • Visualize • Conquer", style: AppTypography.body),

              const SizedBox(height: 60),

              SocialLoginButton(
                text: "Continue with Google",
                icon: Icons.g_mobiledata,
                onPressed: () {
                  context.go(AppRoutes.home);
                },
              ),

              const SizedBox(height: AppSpacing.md),

              SocialLoginButton(
                text: "Continue with Microsoft",
                icon: Icons.business,
                onPressed: () {
                  context.go(AppRoutes.home);
                },
              ),

              const Spacer(),

              Text(
                "By continuing, you agree to our Terms & Privacy Policy.",
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
