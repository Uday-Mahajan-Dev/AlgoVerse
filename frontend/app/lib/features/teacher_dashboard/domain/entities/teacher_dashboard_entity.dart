class TeacherDashboardStats {
  final int totalStudents;
  final int activeStudents;
  final double averageMastery;
  final int problemsSolved;

  const TeacherDashboardStats({
    required this.totalStudents,
    required this.activeStudents,
    required this.averageMastery,
    required this.problemsSolved,
  });
}

class ConceptPerformance {
  final String concept;
  final double mastery;
  final int studentsAttempted;

  const ConceptPerformance({
    required this.concept,
    required this.mastery,
    required this.studentsAttempted,
  });
}

class WeakConcept {
  final String concept;
  final double mastery;
  final int affectedStudents;

  const WeakConcept({
    required this.concept,
    required this.mastery,
    required this.affectedStudents,
  });
}

class RecentActivity {
  final String studentName;
  final String activity;
  final String topic;
  final String time;

  const RecentActivity({
    required this.studentName,
    required this.activity,
    required this.topic,
    required this.time,
  });
}

class TeacherDashboardData {
  final TeacherDashboardStats stats;
  final List<ConceptPerformance> conceptPerformance;
  final List<WeakConcept> weakConcepts;
  final List<RecentActivity> recentActivities;

  const TeacherDashboardData({
    required this.stats,
    required this.conceptPerformance,
    required this.weakConcepts,
    required this.recentActivities,
  });
}
