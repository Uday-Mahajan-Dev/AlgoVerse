import '../../domain/entities/student_dashboard_entity.dart';

class StudentDashboardModel extends StudentDashboardData {
  const StudentDashboardModel({
    required super.user,
    required super.levelXp,
    required super.continueLearning,
    required super.dailyMissions,
    required super.performance,
    required super.nextAchievement,
    required super.weeklyChallenge,
    required super.recentActivities,
  });

  factory StudentDashboardModel.fromJson(Map<String, dynamic> json) {
    final userJson =
        json['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final levelXpJson =
        json['level_xp'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final continueLearningJson =
        json['continue_learning'] as Map<String, dynamic>? ??
            <String, dynamic>{};
    final performanceJson =
        json['performance'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final nextAchievementJson =
        json['next_achievement'] as Map<String, dynamic>? ??
            <String, dynamic>{};
    final weeklyChallengeJson =
        json['weekly_challenge'] as Map<String, dynamic>? ??
            <String, dynamic>{};

    return StudentDashboardModel(
      user: StudentUser(
        id: userJson['id']?.toString() ?? '',
        username: userJson['username'] as String? ?? 'Student',
        firstName: userJson['first_name'] as String? ?? 'Student',
        lastName: userJson['last_name'] as String? ?? '',
        email: userJson['email'] as String? ?? '',
        avatarUrl: userJson['avatar_url'] as String?,
      ),
      levelXp: StudentLevelXp(
        currentLevel: levelXpJson['current_level'] as int? ?? 12,
        currentXp: levelXpJson['current_xp'] as int? ?? 780,
        nextLevelXp: levelXpJson['next_level_xp'] as int? ?? 1000,
        xpToNextLevel: levelXpJson['xp_to_next_level'] as int? ?? 220,
        progress: (levelXpJson['progress'] as num?)?.toDouble() ?? 0.78,
      ),
      continueLearning: StudentContinueLearning(
        category:
            continueLearningJson['category'] as String? ??
            'DATA STRUCTURES & ALGORITHMS',
        topic: continueLearningJson['topic'] as String? ?? 'Binary Trees',
        progress:
            (continueLearningJson['progress'] as num?)?.toDouble() ?? 0.72,
        progressText:
            continueLearningJson['progress_text'] as String? ?? '72% COMPLETE',
      ),
      dailyMissions: (json['daily_missions'] as List<dynamic>? ?? [])
          .map(
            (item) => StudentDailyMission(
              number: item['number'] as String? ?? '01',
              title: item['title'] as String? ?? 'Mission',
              progressText: item['progress_text'] as String? ?? '0/1',
              progress: (item['progress'] as num?)?.toDouble() ?? 0.0,
              reward: item['reward'] as String? ?? '50 XP',
              icon: item['icon'] as String? ?? 'code',
            ),
          )
          .toList(),
      performance: StudentPerformanceStats(
        dayStreak: performanceJson['day_streak'] as int? ?? 12,
        totalXp: performanceJson['total_xp'] as int? ?? 1240,
      ),
      nextAchievement: StudentNextAchievement(
        title: nextAchievementJson['title'] as String? ?? 'PROBLEM SOLVER',
        description:
            nextAchievementJson['description'] as String? ??
            'Solve 100 problems to unlock this achievement.',
        currentCount: nextAchievementJson['current_count'] as int? ?? 87,
        targetCount: nextAchievementJson['target_count'] as int? ?? 100,
        progress:
            (nextAchievementJson['progress'] as num?)?.toDouble() ?? 0.87,
        progressText:
            nextAchievementJson['progress_text'] as String? ??
            '87 / 100 PROBLEMS',
        remainingText:
            nextAchievementJson['remaining_text'] as String? ??
            '13 PROBLEMS TO UNLOCK',
      ),
      weeklyChallenge: StudentWeeklyChallenge(
        title: weeklyChallengeJson['title'] as String? ?? 'ALGORITHM SPRINT',
        description:
            weeklyChallengeJson['description'] as String? ??
            'Solve 10 problems this week.',
        currentCount: weeklyChallengeJson['current_count'] as int? ?? 7,
        targetCount: weeklyChallengeJson['target_count'] as int? ?? 10,
        reward: weeklyChallengeJson['reward'] as String? ?? '200 XP',
        progress:
            (weeklyChallengeJson['progress'] as num?)?.toDouble() ?? 0.7,
        progressText:
            weeklyChallengeJson['progress_text'] as String? ?? '7 / 10 COMPLETE',
      ),
      recentActivities: (json['recent_activities'] as List<dynamic>? ?? [])
          .map(
            (item) => StudentRecentActivity(
              title: item['title'] as String? ?? 'Solved problem',
              xp: item['xp'] as String? ?? '+20 XP',
              icon: item['icon'] as String? ?? 'code',
            ),
          )
          .toList(),
    );
  }

  static StudentDashboardModel defaultSample() {
    return const StudentDashboardModel(
      user: StudentUser(
        id: '',
        username: 'Student',
        firstName: 'Student',
        lastName: '',
        email: '',
      ),
      levelXp: StudentLevelXp(
        currentLevel: 12,
        currentXp: 780,
        nextLevelXp: 1000,
        xpToNextLevel: 220,
        progress: 0.78,
      ),
      continueLearning: StudentContinueLearning(
        category: 'DATA STRUCTURES & ALGORITHMS',
        topic: 'Binary Trees',
        progress: 0.72,
        progressText: '72% COMPLETE',
      ),
      dailyMissions: [
        StudentDailyMission(
          number: '01',
          title: 'Solve 3 Problems',
          progressText: '2 / 3',
          progress: 0.66,
          reward: '50 XP',
          icon: 'code',
        ),
        StudentDailyMission(
          number: '02',
          title: 'Complete a Lesson',
          progressText: '0 / 1',
          progress: 0.0,
          reward: '30 XP',
          icon: 'book',
        ),
        StudentDailyMission(
          number: '03',
          title: 'Daily Challenge',
          progressText: 'AVAILABLE',
          progress: 0.0,
          reward: '75 XP',
          icon: 'target',
        ),
      ],
      performance: StudentPerformanceStats(dayStreak: 12, totalXp: 1240),
      nextAchievement: StudentNextAchievement(
        title: 'PROBLEM SOLVER',
        description: 'Solve 100 problems to unlock this achievement.',
        currentCount: 87,
        targetCount: 100,
        progress: 0.87,
        progressText: '87 / 100 PROBLEMS',
        remainingText: '13 PROBLEMS TO UNLOCK',
      ),
      weeklyChallenge: StudentWeeklyChallenge(
        title: 'ALGORITHM SPRINT',
        description: 'Solve 10 problems this week.',
        currentCount: 7,
        targetCount: 10,
        reward: '200 XP',
        progress: 0.7,
        progressText: '7 / 10 COMPLETE',
      ),
      recentActivities: [
        StudentRecentActivity(
          title: 'Solved Two Sum',
          xp: '+20 XP',
          icon: 'code',
        ),
        StudentRecentActivity(
          title: 'Completed Arrays Basics',
          xp: '+30 XP',
          icon: 'book',
        ),
        StudentRecentActivity(
          title: 'Reached Level 12',
          xp: '+100 XP',
          icon: 'badge',
        ),
      ],
    );
  }
}

class ContinueLearningModel extends ContinueLearningEntity {
  const ContinueLearningModel({
    required super.lessonId,
    required super.lessonTitle,
    required super.lessonSlug,
    required super.courseTitle,
    required super.courseSlug,
    required super.moduleTitle,
    required super.contentType,
    required super.courseCompletionPct,
  });

  factory ContinueLearningModel.fromJson(Map<String, dynamic> json) {
    return ContinueLearningModel(
      lessonId: json['lesson_id']?.toString() ?? '',
      lessonTitle: json['lesson_title']?.toString() ?? '',
      lessonSlug: json['lesson_slug']?.toString() ?? '',
      courseTitle: json['course_title']?.toString() ?? '',
      courseSlug: json['course_slug']?.toString() ?? '',
      moduleTitle: json['module_title']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? 'CONCEPT',
      courseCompletionPct:
          (json['course_completion_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StudentMetricsModel extends StudentMetricsEntity {
  const StudentMetricsModel({
    required super.totalCoursesEnrolled,
    required super.totalLessonsCompleted,
    required super.totalVisualizationsCompleted,
    required super.totalProblemsSolved,
    required super.currentStreak,
  });

  factory StudentMetricsModel.fromJson(Map<String, dynamic> json) {
    return StudentMetricsModel(
      totalCoursesEnrolled: json['total_courses_enrolled'] as int? ?? 0,
      totalLessonsCompleted: json['total_lessons_completed'] as int? ?? 0,
      totalVisualizationsCompleted:
          json['total_visualizations_completed'] as int? ?? 0,
      totalProblemsSolved: json['total_problems_solved'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
    );
  }
}

