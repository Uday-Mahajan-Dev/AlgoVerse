import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/providers/course_provider.dart';
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
    final myTeacherAsync = ref.watch(myTeacherProvider);
    final progressAsync = ref.watch(allStudentProgressProvider);

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
                  onPressed: () => ref.invalidate(studentDashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(studentDashboardProvider);
              ref.invalidate(myTeacherProvider);
              ref.invalidate(allStudentProgressProvider);
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
                    fallbackContinueLearning: data.continueLearning,
                    progressAsync: progressAsync,
                  ),
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

                  const SectionTitle(title: 'YOUR PERFORMANCE'),
                  const SizedBox(height: 12),

                  PerformanceStatsSection(
                    performance: data.performance,
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
// CONTINUE LEARNING
//

class ContinueLearningCard extends StatelessWidget {
  final StudentContinueLearning fallbackContinueLearning;
  final AsyncValue<List<CourseProgressEntity>> progressAsync;

  const ContinueLearningCard({
    super.key,
    required this.fallbackContinueLearning,
    required this.progressAsync,
  });

  @override
  Widget build(BuildContext context) {
    return progressAsync.when(
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
      error: (err, stack) => _buildFallback(context),
      data: (progressList) {

        if (progressList.isEmpty) {
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
                    child:
                        const Icon(Icons.school_outlined, color: Colors.indigo),
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

        final active = progressList.first;
        final progressFraction =
            (active.completionPercentage / 100.0).clamp(0.0, 1.0);

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
                const Icon(Icons.menu_book_outlined, size: 28),
                const SizedBox(height: 16),
                const Text(
                  'COURSE PATHWAY',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  active.courseTitle,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  '${active.completedLessons} of ${active.totalLessons} Lessons Completed (${active.completionPercentage.toStringAsFixed(0)}%)',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/courses/${active.courseSlug}');
                    },
                    child: const Text('CONTINUE LEARNING'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallback(BuildContext context) {
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
            const Icon(Icons.menu_book_outlined, size: 28),
            const SizedBox(height: 16),
            Text(
              fallbackContinueLearning.category,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              fallbackContinueLearning.topic,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              fallbackContinueLearning.progressText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: fallbackContinueLearning.progress.clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push(AppRoutes.courses);
                },
                child: const Text('EXPLORE COURSES'),
              ),
            ),
          ],
        ),
      ),
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
// PERFORMANCE STATS
//

class PerformanceStatsSection extends StatelessWidget {
  final StudentPerformanceStats performance;

  const PerformanceStatsSection({
    super.key,
    required this.performance,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department_outlined,
            value: '${performance.dayStreak}',
            label: 'DAY STREAK',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.bolt_outlined,
            value: '${performance.totalXp}',
            label: 'TOTAL XP',
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
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
            Icon(icon),
            const SizedBox(height: 18),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
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
