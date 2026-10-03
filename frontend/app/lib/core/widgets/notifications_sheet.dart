import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

class NotificationsSheet extends StatefulWidget {
  final VoidCallback? onDismiss;

  const NotificationsSheet({
    super.key,
    this.onDismiss,
  });

  static Future<void> show(BuildContext context, {VoidCallback? onDismiss}) {
    final theme = Theme.of(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => NotificationsSheet(onDismiss: onDismiss),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      final res = await ApiClient.getNotifications(accessToken: token);
      final rawList = res['notifications'] as List? ?? [];
      final unread = res['unread_count'] as int? ?? 0;

      if (mounted) {
        setState(() {
          _notifications = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _unreadCount = unread;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markRead(String notifId, int index) async {
    if (_notifications[index]['is_read'] == true) return;

    setState(() {
      _notifications[index]['is_read'] = true;
      if (_unreadCount > 0) _unreadCount--;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      await ApiClient.markNotificationRead(
        accessToken: token,
        notificationId: notifId,
      );
      widget.onDismiss?.call();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (final n in _notifications) {
        n['is_read'] = true;
      }
      _unreadCount = 0;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      await ApiClient.markAllNotificationsRead(accessToken: token);
      widget.onDismiss?.call();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null) return 'Recently';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (scrollContext, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_unreadCount new',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                    ),
                  IconButton(
                    onPressed: () {
                      widget.onDismiss?.call();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _buildContent(scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 44, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchNotifications,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_paused_rounded,
                  size: 44,
                  color: Colors.purple.shade400,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'All caught up!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Homework assignments, live quizzes, and achievement alerts will appear here in real time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final id = notif['id']?.toString() ?? '';
          final title = notif['title']?.toString() ?? 'Notification';
          final message = notif['message']?.toString() ?? '';
          final type = notif['type']?.toString().toUpperCase() ?? 'SYSTEM';
          final isRead = notif['is_read'] == true;
          final timeStr = _formatTime(notif['created_at']);

          IconData icon;
          Color iconColor;

          switch (type) {
            case 'HOMEWORK':
              icon = Icons.assignment_rounded;
              iconColor = const Color(0xFF0D9488);
              break;
            case 'QUIZ':
              icon = Icons.sports_esports_rounded;
              iconColor = const Color(0xFFD97706);
              break;
            case 'BADGE':
              icon = Icons.military_tech_rounded;
              iconColor = const Color(0xFF7C3AED);
              break;
            default:
              icon = Icons.notifications_active_rounded;
              iconColor = const Color(0xFF2563EB);
          }

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await _markRead(id, index);
              if (!mounted || !context.mounted) return;
              // Route to relevant page if appropriate
              if (type == 'QUIZ') {
                Navigator.of(context).pop();
                if (context.mounted) {
                  context.push(AppRoutes.quizzes);
                }
              } else if (type == 'BADGE') {
                Navigator.of(context).pop();
                if (context.mounted) {
                  context.push(AppRoutes.profile);
                }
              }
            },

            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: !isRead
                    ? iconColor.withValues(alpha: 0.07)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !isRead
                      ? iconColor.withValues(alpha: 0.3)
                      : Colors.grey.shade200,
                  width: !isRead ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: !isRead ? FontWeight.bold : FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: iconColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
