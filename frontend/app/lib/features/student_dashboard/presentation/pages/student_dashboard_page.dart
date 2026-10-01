import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../learning/domain/entities/ai_tutor_entity.dart';
import '../../../learning/presentation/providers/ai_tutor_provider.dart';
import '../../../teacher_dashboard/domain/entities/teacher_analytics_entity.dart';
import '../../../teacher_dashboard/presentation/providers/teacher_analytics_provider.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/presentation/providers/teacher_provider.dart';
import '../../domain/entities/student_dashboard_entity.dart';
import '../providers/student_dashboard_provider.dart';

class StudentDashboardPage extends ConsumerStatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  ConsumerState<StudentDashboardPage> createState() =>
      _StudentDashboardPageState();
}

class _StudentDashboardPageState extends ConsumerState<StudentDashboardPage> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from AlgoVerse?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await TokenStorage.clear();

      if (!mounted) return;

      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to logout. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(studentDashboardProvider);
    final continueLearningAsync = ref.watch(continueLearningProvider);
    final metricsAsync = ref.watch(studentMetricsProvider);
    final myTeacherAsync = ref.watch(myTeacherProvider);
    final progressAsync = ref.watch(allStudentProgressProvider);
    final studentAssignmentsAsync = ref.watch(studentAssignmentsProvider);
    final aiRecommendationsAsync = ref.watch(aiRecommendationsProvider);

    return Scaffold(
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48),
                const SizedBox(height: 12),
                const Text('Unable to load dashboard data.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(studentDashboardProvider);
                    ref.invalidate(continueLearningProvider);
                    ref.invalidate(studentMetricsProvider);
                    ref.invalidate(myTeacherProvider);
                    ref.invalidate(allStudentProgressProvider);
                    ref.invalidate(studentAssignmentsProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(studentDashboardProvider);
              ref.invalidate(continueLearningProvider);
              ref.invalidate(studentMetricsProvider);
              ref.invalidate(myTeacherProvider);
              ref.invalidate(allStudentProgressProvider);
              ref.invalidate(studentAssignmentsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardHeader(
                    user: data.user,
                    onLogout: _logout,
                    isLoggingOut: _isLoggingOut,
                  ),
                  const SizedBox(height: 28),

                  LevelXpCard(levelXp: data.levelXp),
                  const SizedBox(height: 28),

                  MentorSection(myTeacherAsync: myTeacherAsync),
                  const SizedBox(height: 28),

                  SectionTitle(
                    title: 'CONTINUE YOUR JOURNEY',
                    action: 'EXPLORE COURSES',
                    onActionTap: () => context.push(AppRoutes.courses),
                  ),
                  const SizedBox(height: 12),

                  ContinueLearningCard(
                    continueLearningAsync: continueLearningAsync,
                    fallbackContinueLearning: data.continueLearning,
                  ),
                  const SizedBox(height: 28),

                  const SectionTitle(title: 'YOUR HOMEWORK & ASSIGNMENTS'),
                  const SizedBox(height: 12),
                  StudentHomeworkSection(assignmentsAsync: studentAssignmentsAsync),
                  const SizedBox(height: 28),

                  const SectionTitle(title: '🤖 AI RECOMMENDED FOR YOU'),
                  const SizedBox(height: 12),
                  AIRecommendationsSection(recsAsync: aiRecommendationsAsync),
                  const SizedBox(height: 28),

                  const SectionTitle(title: 'YOUR PERFORMANCE'),
                  const SizedBox(height: 12),

                  PerformanceStatsSection(
                    metricsAsync: metricsAsync,
                    fallbackPerformance: data.performance,
                  ),
                  const SizedBox(height: 28),

                  SectionTitle(
                    title: 'ENROLLED COURSES',
                    action: 'ALL COURSES',
                    onActionTap: () => context.push(AppRoutes.courses),
                  ),
                  const SizedBox(height: 12),

                  EnrolledCoursesSection(progressAsync: progressAsync),
                  const SizedBox(height: 28),

                  const SectionTitle(
                    title: 'DAILY MISSIONS',
                    action: 'VIEW ALL',
                  ),
                  const SizedBox(height: 12),

                  DailyMissionsSection(
                    dailyMissions: data.dailyMissions,
                  ),
                  const SizedBox(height: 28),

                  const SectionTitle(title: 'NEXT ACHIEVEMENT'),
                  const SizedBox(height: 12),

                  NextAchievementCard(
                    nextAchievement: data.nextAchievement,
                  ),
                  const SizedBox(height: 28),

                  const SectionTitle(title: 'WEEKLY CHALLENGE'),
                  const SizedBox(height: 12),

                  WeeklyChallengeCard(
                    weeklyChallenge: data.weeklyChallenge,
                  ),
                  const SizedBox(height: 28),

                  const SectionTitle(title: 'RECENT ACTIVITY'),
                  const SizedBox(height: 12),

                  RecentActivitySection(
                    activities: data.recentActivities,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//
// HEADER
//

class DashboardHeader extends StatelessWidget {
  final StudentUser user;
  final VoidCallback onLogout;
  final bool isLoggingOut;

  const DashboardHeader({
    super.key,
    required this.user,
    required this.onLogout,
    required this.isLoggingOut,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${user.displayName}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Continue building your problem-solving skills.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: isLoggingOut ? null : () {},
          icon: const Icon(Icons.notifications_none_outlined),
          tooltip: 'Notifications',
        ),
        IconButton(
          onPressed: isLoggingOut ? null : onLogout,
          icon: isLoggingOut
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout_outlined),
          tooltip: 'Logout',
        ),
      ],
    );
  }
}

//
// SECTION TITLE
//

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onActionTap ?? () {},
            child: Text(action!),
          ),
      ],
    );
  }
}

//
// LEVEL + XP CARD
//

class LevelXpCard extends StatelessWidget {
  final StudentLevelXp levelXp;

  const LevelXpCard({super.key, required this.levelXp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'CURRENT LEVEL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${levelXp.currentLevel}',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'LEVEL',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: levelXp.progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${levelXp.currentXp} / ${levelXp.nextLevelXp} XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${levelXp.xpToNextLevel} XP TO NEXT LEVEL',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//
// CONTINUE LEARNING (4-PRIORITY RESOLVER)
//

class ContinueLearningCard extends StatelessWidget {
  final AsyncValue<ContinueLearningEntity?> continueLearningAsync;
  final StudentContinueLearning fallbackContinueLearning;

  const ContinueLearningCard({
    super.key,
    required this.continueLearningAsync,
    required this.fallbackContinueLearning,
  });

  Color _getContentTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'VISUALIZATION':
        return Colors.purple;
      case 'PROBLEM':
        return Colors.orange;
      case 'CONCEPT':
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return continueLearningAsync.when(
      loading: () => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: const Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => _buildEmptyCard(context),
      data: (item) {
        if (item == null) {
          return _buildEmptyCard(context);
        }

        final typeColor = _getContentTypeColor(item.contentType);
        final progressFraction =
            (item.courseCompletionPct / 100.0).clamp(0.0, 1.0);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with Category and Content Type chip
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.courseTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.contentType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Lesson Title
                Text(
                  item.lessonTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Module Title
                Text(
                  'Module: ${item.moduleTitle}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),

                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Course Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${item.courseCompletionPct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                ),
                const SizedBox(height: 20),

                // Resume Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push(
                        '/courses/${item.courseSlug}/lessons/${item.lessonSlug}',
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text(
                      'RESUME LESSON',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_outlined, color: Colors.indigo),
            ),
            const SizedBox(height: 14),
            const Text(
              'Start Your DSA Journey',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Enroll in our structured pathways (Arrays, Binary Trees, Dynamic Programming) to begin interactive learning.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.courses),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('EXPLORE COURSE PATHWAYS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// PERFORMANCE STATS (LIVE METRICS)
//

class PerformanceStatsSection extends StatelessWidget {
  final AsyncValue<StudentMetricsEntity> metricsAsync;
  final StudentPerformanceStats fallbackPerformance;

  const PerformanceStatsSection({
    super.key,
    required this.metricsAsync,
    required this.fallbackPerformance,
  });

  @override
  Widget build(BuildContext context) {
    return metricsAsync.when(
      loading: () => Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.orange,
              value: '${fallbackPerformance.dayStreak}',
              label: 'DAY STREAK',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.bolt_outlined,
              iconColor: Colors.amber,
              value: '${fallbackPerformance.totalXp}',
              label: 'TOTAL XP',
            ),
          ),
        ],
      ),
      error: (err, stack) => Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.orange,
              value: '${fallbackPerformance.dayStreak}',
              label: 'DAY STREAK',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.bolt_outlined,
              iconColor: Colors.amber,
              value: '${fallbackPerformance.totalXp}',
              label: 'TOTAL XP',
            ),
          ),
        ],
      ),
      data: (metrics) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.orange,
                    value: '${metrics.currentStreak}',
                    label: 'DAY STREAK',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.task_alt_rounded,
                    iconColor: Colors.green,
                    value: '${metrics.totalLessonsCompleted}',
                    label: 'LESSONS DONE',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.insights_rounded,
                    iconColor: Colors.purple,
                    value: '${metrics.totalVisualizationsCompleted}',
                    label: 'VISUALIZATIONS',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.school_outlined,
                    iconColor: Colors.indigo,
                    value: '${metrics.totalCoursesEnrolled}',
                    label: 'ENROLLED PATHS',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    this.iconColor = Colors.indigo,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ENROLLED COURSES SECTION
//

class EnrolledCoursesSection extends StatelessWidget {
  final AsyncValue<List<CourseProgressEntity>> progressAsync;

  const EnrolledCoursesSection({
    super.key,
    required this.progressAsync,
  });

  @override
  Widget build(BuildContext context) {
    return progressAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => const SizedBox.shrink(),
      data: (progressList) {
        if (progressList.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'You are not currently enrolled in any courses.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.courses),
                    child: const Text('Browse'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: progressList.map((course) {
            final progressFraction =
                (course.completionPercentage / 100.0).clamp(0.0, 1.0);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.push('/courses/${course.courseSlug}'),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.courseTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${course.completionPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${course.completedLessons} of ${course.totalLessons} Lessons Completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.indigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

//
// DAILY MISSIONS
//

class DailyMissionsSection extends StatelessWidget {
  final List<StudentDailyMission> dailyMissions;

  const DailyMissionsSection({
    super.key,
    required this.dailyMissions,
  });

  IconData _mapIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'code':
        return Icons.code_outlined;
      case 'book':
        return Icons.menu_book_outlined;
      case 'target':
        return Icons.track_changes_outlined;
      default:
        return Icons.task_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: dailyMissions.map((mission) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MissionCard(
            number: mission.number,
            title: mission.title,
            progressText: mission.progressText,
            progress: mission.progress,
            reward: mission.reward,
            icon: _mapIcon(mission.icon),
          ),
        );
      }).toList(),
    );
  }
}

class MissionCard extends StatelessWidget {
  final String number;
  final String title;
  final String progressText;
  final double progress;
  final String reward;
  final IconData icon;

  const MissionCard({
    super.key,
    required this.number,
    required this.title,
    required this.progressText,
    required this.progress,
    required this.reward,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.indigo),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number  $title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'REWARD  $reward',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              progressText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

//
// NEXT ACHIEVEMENT
//

class NextAchievementCard extends StatelessWidget {
  final StudentNextAchievement nextAchievement;

  const NextAchievementCard({
    super.key,
    required this.nextAchievement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.military_tech_outlined, size: 30),
          const SizedBox(height: 18),
          Text(
            nextAchievement.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(nextAchievement.description),
          const SizedBox(height: 20),
          Text(
            nextAchievement.progressText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: nextAchievement.progress.clamp(0.0, 1.0),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nextAchievement.remainingText,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

//
// WEEKLY CHALLENGE
//

class WeeklyChallengeCard extends StatelessWidget {
  final StudentWeeklyChallenge weeklyChallenge;

  const WeeklyChallengeCard({
    super.key,
    required this.weeklyChallenge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.leaderboard_outlined, size: 30),
            const SizedBox(height: 18),
            Text(
              weeklyChallenge.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(weeklyChallenge.description),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  weeklyChallenge.progressText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  weeklyChallenge.reward,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: weeklyChallenge.progress.clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// RECENT ACTIVITY
//

class RecentActivitySection extends StatelessWidget {
  final List<StudentRecentActivity> activities;

  const RecentActivitySection({
    super.key,
    required this.activities,
  });

  IconData _mapActivityIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'code':
        return Icons.code_outlined;
      case 'book':
        return Icons.menu_book_outlined;
      case 'badge':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.star_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          final isLast = index == activities.length - 1;

          return Column(
            children: [
              ActivityTile(
                title: activity.title,
                xp: activity.xp,
                icon: _mapActivityIcon(activity.icon),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  final String title;
  final String xp;
  final IconData icon;

  const ActivityTile({
    super.key,
    required this.title,
    required this.xp,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Text(xp, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

//
// MENTOR SECTION
//

class MentorSection extends StatelessWidget {
  final AsyncValue<MyTeacherEntity> myTeacherAsync;

  const MentorSection({
    super.key,
    required this.myTeacherAsync,
  });

  @override
  Widget build(BuildContext context) {
    return myTeacherAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (myTeacher) {
        if (myTeacher.hasTeacher && myTeacher.teacher != null) {
          final teacher = myTeacher.teacher!;
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_outlined, color: Colors.indigo),
                      const SizedBox(width: 8),
                      const Text(
                        'MY MENTOR TEACHER',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          context.push(AppRoutes.teachers);
                        },
                        child: const Text('Change Mentor'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                        backgroundImage: teacher.avatarUrl != null
                            ? NetworkImage(teacher.avatarUrl!)
                            : null,
                        child: teacher.avatarUrl == null
                            ? Text(
                                teacher.displayName.isNotEmpty
                                    ? teacher.displayName[0].toUpperCase()
                                    : 'T',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher.displayName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              teacher.specialty,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                        onPressed: () {
                          context.push('/teachers/${teacher.id}');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Student has no mentor teacher yet -> Show CTA Banner
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.indigo.shade900,
                Colors.indigo.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_search_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Choose Your Mentor Teacher',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Connect with a verified faculty mentor to track your learning journey and get personalized problem guidance.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  context.push(AppRoutes.teachers);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo.shade900,
                ),
                child: const Text(
                  'Explore Teachers Catalog',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StudentHomeworkSection extends StatelessWidget {
  final AsyncValue<List<AssignmentEntity>> assignmentsAsync;

  const StudentHomeworkSection({
    super.key,
    required this.assignmentsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return assignmentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          'Unable to load assignments: $e',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
      data: (assignments) {
        if (assignments.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Caught Up!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No pending homework from your mentor teacher.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assignments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final a = assignments[index];
            final isOverdue = a.isOverdue;
            final isCompleted = a.isCompleted;

            Color statusColor;
            String statusText;
            if (isCompleted) {
              statusColor = const Color(0xFF10B981);
              statusText = 'COMPLETED';
            } else if (isOverdue) {
              statusColor = const Color(0xFFEF4444);
              statusText = 'OVERDUE';
            } else {
              statusColor = const Color(0xFF3B82F6);
              statusText = 'PENDING';
            }

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOverdue ? Colors.red.shade200 : const Color(0xFFE2E8F0),
                  width: isOverdue ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Assigned by ${a.teacherName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      if (a.dueDate != null)
                        Text(
                          'Due: ${a.dueDate!.month}/${a.dueDate!.day}/${a.dueDate!.year}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOverdue ? Colors.red : Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    a.lessonTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.courseTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (a.notes != null && a.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Note: ${a.notes!}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.push(
                          '/courses/${a.courseSlug}/lessons/${a.lessonSlug}',
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isCompleted
                            ? Colors.grey.shade700
                            : (isOverdue ? Colors.red.shade700 : Colors.indigo),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        isCompleted
                            ? Icons.replay_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isCompleted ? 'Review Lesson' : 'Start Assignment',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AIRecommendationsSection extends StatelessWidget {
  final AsyncValue<List<AIRecommendationEntity>> recsAsync;

  const AIRecommendationsSection({
    super.key,
    required this.recsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return recsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.indigo, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI mentorship recommendations will appear here as you practice.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
      data: (recs) {
        if (recs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Great progress! Check back later for personalized AI problem recommendations.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final rec = recs[index];
            Color priorityColor;
            switch (rec.priority.toLowerCase()) {
              case 'high':
                priorityColor = Colors.red.shade600;
                break;
              case 'medium':
                priorityColor = Colors.amber.shade700;
                break;
              default:
                priorityColor = Colors.blue.shade600;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: priorityColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rec.lessonTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${rec.priority.toUpperCase()} PRIORITY',
                                style: TextStyle(
                                  color: priorityColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec.reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Course: ${rec.courseTitle}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
