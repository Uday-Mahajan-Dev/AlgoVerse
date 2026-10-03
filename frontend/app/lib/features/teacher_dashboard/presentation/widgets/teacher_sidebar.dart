import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class TeacherSidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const TeacherSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authNotifierProvider.notifier).logout(context: context);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    } catch (_) {
      if (context.mounted) {
        context.go(AppRoutes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);


    return Container(
      width: 260,
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
              child: Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    color: Colors.purple.shade700,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'FACULTY HUB',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.purple.shade900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _SidebarItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    selected: selectedIndex == 0,
                    onTap: () => onItemSelected(0),
                  ),
                  _SidebarItem(
                    icon: Icons.edit_note_rounded,
                    title: 'Educator Studio (Quizzes & Problems)',
                    selected: selectedIndex == 1,
                    onTap: () {
                      context.push(AppRoutes.educatorStudio);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.person_rounded,
                    title: 'Profile & Badges',
                    selected: false,
                    onTap: () => context.push(AppRoutes.profile),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              child: _SidebarItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                selected: false,
                iconColor: Colors.red.shade700,
                textColor: Colors.red.shade700,
                onTap: () => _logout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        selectedTileColor: Colors.purple.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          color: selected
              ? Colors.purple.shade700
              : (iconColor ?? theme.colorScheme.onSurfaceVariant),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected
                ? Colors.purple.shade900
                : (textColor ?? theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}