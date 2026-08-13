import '../../domain/entities/teacher_dashboard_entity.dart';

class TeacherDashboardModel extends TeacherDashboardData {
  const TeacherDashboardModel({
    required super.stats,
    required super.conceptPerformance,
    required super.weakConcepts,
    required super.recentActivities,
  });

  factory TeacherDashboardModel.fromJson(Map<String, dynamic> json) {
    final statsJson =
        json['stats'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return TeacherDashboardModel(
      stats: TeacherDashboardStats(
        totalStudents: statsJson['total_students'] as int? ?? 0,
        activeStudents: statsJson['active_students'] as int? ?? 0,
        averageMastery:
            (statsJson['average_mastery'] as num?)?.toDouble() ?? 0.0,
        problemsSolved: statsJson['problems_solved'] as int? ?? 0,
      ),
      conceptPerformance:
          (json['concept_performance'] as List<dynamic>? ?? [])
              .map(
                (item) => ConceptPerformance(
                  concept: item['concept'] as String? ?? '',
                  mastery: (item['mastery'] as num?)?.toDouble() ?? 0.0,
                  studentsAttempted:
                      item['students_attempted'] as int? ?? 0,
                ),
              )
              .toList(),
      weakConcepts: (json['weak_concepts'] as List<dynamic>? ?? [])
          .map(
            (item) => WeakConcept(
              concept: item['concept'] as String? ?? '',
              mastery: (item['mastery'] as num?)?.toDouble() ?? 0.0,
              affectedStudents:
                  item['affected_students'] as int? ?? 0,
            ),
          )
          .toList(),
      recentActivities:
          (json['recent_activity'] as List<dynamic>? ?? [])
              .map(
                (item) => RecentActivity(
                  studentName: item['student_name'] as String? ?? '',
                  activity: item['activity'] as String? ?? '',
                  topic: item['topic'] as String? ?? '',
                  time: item['time'] as String? ?? '',
                ),
              )
              .toList(),
    );
  }
}