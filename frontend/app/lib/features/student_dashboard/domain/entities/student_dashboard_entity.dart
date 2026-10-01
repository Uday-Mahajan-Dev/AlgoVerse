class StudentUser {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;

  const StudentUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
  });

  String get displayName => firstName.isNotEmpty ? firstName : username;
}

class StudentLevelXp {
  final int currentLevel;
  final int currentXp;
  final int nextLevelXp;
  final int xpToNextLevel;
  final double progress;

  const StudentLevelXp({
    required this.currentLevel,
    required this.currentXp,
    required this.nextLevelXp,
    required this.xpToNextLevel,
    required this.progress,
  });
}

class StudentContinueLearning {
  final String category;
  final String topic;
  final double progress;
  final String progressText;

  const StudentContinueLearning({
    required this.category,
    required this.topic,
    required this.progress,
    required this.progressText,
  });
}

class ContinueLearningEntity {
  final String lessonId;
  final String lessonTitle;
  final String lessonSlug;
  final String courseTitle;
  final String courseSlug;
  final String moduleTitle;
  final String contentType;
  final double courseCompletionPct;

  const ContinueLearningEntity({
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonSlug,
    required this.courseTitle,
    required this.courseSlug,
    required this.moduleTitle,
    required this.contentType,
    required this.courseCompletionPct,
  });
}

class StudentMetricsEntity {
  final int totalCoursesEnrolled;
  final int totalLessonsCompleted;
  final int totalVisualizationsCompleted;
  final int totalProblemsSolved;
  final int currentStreak;

  const StudentMetricsEntity({
    required this.totalCoursesEnrolled,
    required this.totalLessonsCompleted,
    required this.totalVisualizationsCompleted,
    required this.totalProblemsSolved,
    required this.currentStreak,
  });

  const StudentMetricsEntity.empty()
      : totalCoursesEnrolled = 0,
        totalLessonsCompleted = 0,
        totalVisualizationsCompleted = 0,
        totalProblemsSolved = 0,
        currentStreak = 0;
}

class StudentDailyMission {
  final String number;
  final String title;
  final String progressText;
  final double progress;
  final String reward;
  final String icon;

  const StudentDailyMission({
    required this.number,
    required this.title,
    required this.progressText,
    required this.progress,
    required this.reward,
    required this.icon,
  });
}

class StudentPerformanceStats {
  final int dayStreak;
  final int totalXp;

  const StudentPerformanceStats({
    required this.dayStreak,
    required this.totalXp,
  });
}

class StudentNextAchievement {
  final String title;
  final String description;
  final int currentCount;
  final int targetCount;
  final double progress;
  final String progressText;
  final String remainingText;

  const StudentNextAchievement({
    required this.title,
    required this.description,
    required this.currentCount,
    required this.targetCount,
    required this.progress,
    required this.progressText,
    required this.remainingText,
  });
}

class StudentWeeklyChallenge {
  final String title;
  final String description;
  final int currentCount;
  final int targetCount;
  final String reward;
  final double progress;
  final String progressText;

  const StudentWeeklyChallenge({
    required this.title,
    required this.description,
    required this.currentCount,
    required this.targetCount,
    required this.reward,
    required this.progress,
    required this.progressText,
  });
}

class StudentRecentActivity {
  final String title;
  final String xp;
  final String icon;

  const StudentRecentActivity({
    required this.title,
    required this.xp,
    required this.icon,
  });
}

class StudentDashboardData {
  final StudentUser user;
  final StudentLevelXp levelXp;
  final StudentContinueLearning continueLearning;
  final List<StudentDailyMission> dailyMissions;
  final StudentPerformanceStats performance;
  final StudentNextAchievement nextAchievement;
  final StudentWeeklyChallenge weeklyChallenge;
  final List<StudentRecentActivity> recentActivities;

  const StudentDashboardData({
    required this.user,
    required this.levelXp,
    required this.continueLearning,
    required this.dailyMissions,
    required this.performance,
    required this.nextAchievement,
    required this.weeklyChallenge,
    required this.recentActivities,
  });
}
