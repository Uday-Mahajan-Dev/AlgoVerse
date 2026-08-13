import 'package:flutter/material.dart';

class TeacherSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const TeacherSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 250,
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
              child: Row(
                children: [
                  Icon(
                    Icons.code_rounded,
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ALGOVERSE',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
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
                    icon: Icons.people_alt_rounded,
                    title: 'Students',
                    selected: selectedIndex == 1,
                    onTap: () => onItemSelected(1),
                  ),
                  _SidebarItem(
                    icon: Icons.class_rounded,
                    title: 'Classes',
                    selected: selectedIndex == 2,
                    onTap: () => onItemSelected(2),
                  ),
                  _SidebarItem(
                    icon: Icons.analytics_rounded,
                    title: 'Analytics',
                    selected: selectedIndex == 3,
                    onTap: () => onItemSelected(3),
                  ),
                  _SidebarItem(
                    icon: Icons.code_rounded,
                    title: 'Problems',
                    selected: selectedIndex == 4,
                    onTap: () => onItemSelected(4),
                  ),
                  _SidebarItem(
                    icon: Icons.auto_stories_rounded,
                    title: 'Learning Content',
                    selected: selectedIndex == 5,
                    onTap: () => onItemSelected(5),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              child: _SidebarItem(
                icon: Icons.settings_rounded,
                title: 'Settings',
                selected: selectedIndex == 6,
                onTap: () => onItemSelected(6),
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

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        leading: Icon(icon),
        title: Text(title),
      ),
    );
  }
}