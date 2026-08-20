import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/teacher_dashboard_entity.dart';
import '../providers/teacher_dashboard_provider.dart';
import '../widgets/concept_performance_card.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/teacher_sidebar.dart';
import '../widgets/teacher_top_bar.dart';
import '../widgets/weak_concepts_card.dart';

class TeacherDashboardPage extends ConsumerStatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  ConsumerState<TeacherDashboardPage> createState() =>
      _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends ConsumerState<TeacherDashboardPage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(teacherDashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,

      drawer: MediaQuery.sizeOf(context).width < 900
          ? Drawer(
              child: TeacherSidebar(
                selectedIndex: selectedIndex,
                onItemSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });

                  Navigator.of(context).pop();
                },
              ),
            )
          : null,

      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 900)
            TeacherSidebar(
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
            ),

          Expanded(
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    return TeacherTopBar(
                      onMenuPressed: MediaQuery.sizeOf(context).width < 900
                          ? () {
                              Scaffold.of(context).openDrawer();
                            }
                          : null,
                    );
                  },
                ),

                Expanded(
                  child: dashboardAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),

                    error: (error, stackTrace) => _ErrorView(
                      onRetry: () {
                        ref.invalidate(teacherDashboardProvider);
                      },
                    ),

                    data: (dashboard) {
                      return _DashboardContent(dashboard: dashboard);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final TeacherDashboardData dashboard;

  const _DashboardContent({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final stats = dashboard.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teacher Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Monitor your students and track their DSA learning progress.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 28),

              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  final cardWidth = width >= 1200
                      ? (width - 48) / 4
                      : width >= 700
                      ? (width - 16) / 2
                      : width;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: DashboardStatCard(
                          title: 'Total Students',
                          value: '${stats.totalStudents}',
                          subtitle: 'Students enrolled',
                          icon: Icons.people_alt_rounded,
                        ),
                      ),

                      SizedBox(
                        width: cardWidth,
                        child: DashboardStatCard(
                          title: 'Active Students',
                          value: '${stats.activeStudents}',
                          subtitle: 'Currently learning',
                          icon: Icons.person_rounded,
                        ),
                      ),

                      SizedBox(
                        width: cardWidth,
                        child: DashboardStatCard(
                          title: 'Average Mastery',
                          value: '${(stats.averageMastery * 100).round()}%',
                          subtitle: 'Across DSA concepts',
                          icon: Icons.trending_up_rounded,
                        ),
                      ),

                      SizedBox(
                        width: cardWidth,
                        child: DashboardStatCard(
                          title: 'Problems Solved',
                          value: '${stats.problemsSolved}',
                          subtitle: 'Total class submissions',
                          icon: Icons.code_rounded,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              ConceptPerformanceCard(concepts: dashboard.conceptPerformance),

              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: WeakConceptsCard(
                            concepts: dashboard.weakConcepts,
                          ),
                        ),

                        const SizedBox(width: 24),

                        Expanded(
                          child: RecentActivityCard(
                            activities: dashboard.recentActivities,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      WeakConceptsCard(concepts: dashboard.weakConcepts),

                      const SizedBox(height: 24),

                      RecentActivityCard(
                        activities: dashboard.recentActivities,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48),

          const SizedBox(height: 12),

          const Text('Unable to load dashboard data.'),

          const SizedBox(height: 12),

          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
