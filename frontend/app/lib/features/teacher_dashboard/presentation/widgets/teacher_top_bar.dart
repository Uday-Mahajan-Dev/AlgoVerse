import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/widgets/notifications_sheet.dart';

class TeacherTopBar extends StatefulWidget {
  final VoidCallback? onMenuPressed;

  const TeacherTopBar({
    super.key,
    this.onMenuPressed,
  });

  @override
  State<TeacherTopBar> createState() => _TeacherTopBarState();
}

class _TeacherTopBarState extends State<TeacherTopBar> {
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token != null) {
        final res = await ApiClient.getNotifications(accessToken: token, limit: 1);
        final unread = res['unread_count'] as int? ?? 0;
        if (mounted) {
          setState(() {
            _hasUnreadNotifications = unread > 0;
          });
        }
      }
    } catch (_) {}
  }

  void _showNotifications(BuildContext context) {
    NotificationsSheet.show(
      context,
      onDismiss: _checkNotifications,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: Row(
          children: [
            if (widget.onMenuPressed != null) ...[
              IconButton(
                onPressed: widget.onMenuPressed,
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Navigation Menu',
              ),
              const SizedBox(width: 8),
            ],
            Text(
              'Faculty Analytics Hub',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade900,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showNotifications(context),
              icon: Badge(
                isLabelVisible: _hasUnreadNotifications,
                smallSize: 8,
                backgroundColor: Colors.deepOrangeAccent,
                child: const Icon(Icons.notifications_none_rounded),
              ),
              tooltip: 'Notifications',
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Profile & Settings',
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push(AppRoutes.profile),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}