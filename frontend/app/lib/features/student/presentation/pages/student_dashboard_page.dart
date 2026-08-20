import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../auth/data/social_auth_service.dart';
import '../widgets/student_empty_state_card.dart';
import '../widgets/student_header.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  String _studentName = 'Student';
  bool _isLoadingName = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = await TokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final profile = await ApiClient.me(token);
        final firstName = profile['first_name']?.toString();
        if (firstName != null && firstName.isNotEmpty) {
          if (mounted) {
            setState(() {
              _studentName = firstName;
            });
          }
        }
      } catch (_) {
        // Fallback to default name
      }
    }
    if (mounted) {
      setState(() {
        _isLoadingName = false;
      });
    }
  }

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
        } catch (_) {}
      }

      try {
        await SocialAuthService.signOut();
      } catch (_) {}

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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon!')));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar Row with Logout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              TextButton.icon(
                onPressed: _isLoggingOut ? null : _logout,
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Header Section
          StudentHeader(userName: _isLoadingName ? 'Student' : _studentName),

          const SizedBox(height: AppSpacing.lg),

          // Quick Actions
          Row(
            children: [
              _QuickActionButton(
                icon: Icons.menu_book_rounded,
                label: 'Courses',
                onTap: () => _showComingSoon('Courses'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuickActionButton(
                icon: Icons.code_rounded,
                label: 'Practice',
                onTap: () => _showComingSoon('Practice'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuickActionButton(
                icon: Icons.insights_rounded,
                label: 'Progress',
                onTap: () => _showComingSoon('Progress'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuickActionButton(
                icon: Icons.person_search_rounded,
                label: 'Teacher',
                onTap: () => _showComingSoon('Teacher Discovery'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Continue Learning
          const SectionTitle(title: 'CONTINUE LEARNING'),
          const SizedBox(height: AppSpacing.sm),
          const StudentEmptyStateCard(
            icon: Icons.play_circle_outline_rounded,
            title: 'No Active Learning Track',
            description:
                'You have not started any learning tracks yet. Your ongoing DSA modules will appear here.',
          ),

          const SizedBox(height: AppSpacing.xl),

          // My Courses
          const SectionTitle(title: 'MY COURSES'),
          const SizedBox(height: AppSpacing.sm),
          const StudentEmptyStateCard(
            icon: Icons.collections_bookmark_outlined,
            title: 'No Enrolled Courses',
            description:
                'Explore and enroll in structured DSA courses once enrollment opens.',
          ),

          const SizedBox(height: AppSpacing.xl),

          // Learning Progress
          const SectionTitle(title: 'LEARNING PROGRESS'),
          const SizedBox(height: AppSpacing.sm),
          const StudentEmptyStateCard(
            icon: Icons.bar_chart_rounded,
            title: 'No Learning Metrics Yet',
            description:
                'Solve practice problems and complete lessons to unlock performance statistics.',
          ),

          const SizedBox(height: AppSpacing.xl),

          // Teacher Section
          const SectionTitle(title: 'TEACHER & MENTORSHIP'),
          const SizedBox(height: AppSpacing.sm),
          StudentEmptyStateCard(
            icon: Icons.school_outlined,
            title: 'Connect with a Teacher',
            description:
                'Join a class or assign a mentor to receive personalized problem sets and feedback.',
            buttonText: 'Find a Teacher',
            onButtonPressed: () => _showComingSoon('Teacher Discovery'),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
