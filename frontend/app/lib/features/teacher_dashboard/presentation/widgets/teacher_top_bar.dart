import 'package:flutter/material.dart';

class TeacherTopBar extends StatelessWidget {
  final VoidCallback? onMenuPressed;

  const TeacherTopBar({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search students, problems, concepts...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(child: Icon(Icons.person_rounded)),
        ],
      ),
    );
  }
}
