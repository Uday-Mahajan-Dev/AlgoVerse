import '../../domain/entities/teacher_analytics_entity.dart';

class RecentActivityItemModel extends RecentActivityItemEntity {
  const RecentActivityItemModel({
    required super.studentName,
    super.studentAvatar,
    required super.actionType,
    required super.itemTitle,
    required super.timestamp,
  });

  factory RecentActivityItemModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityItemModel(
      studentName: json['student_name'] as String? ?? 'Student',
      studentAvatar: json['student_avatar'] as String?,
      actionType: json['action_type'] as String? ?? 'COMPLETED_LESSON',
      itemTitle: json['item_title'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

class TeacherOverviewModel extends TeacherOverviewEntity {
  const TeacherOverviewModel({
    required super.totalStudents,
    required super.activeStudents,
    required super.avgCourseCompletion,
    required super.totalSubmissionsToday,
    required super.recentActivityFeed,
  });

  factory TeacherOverviewModel.fromJson(Map<String, dynamic> json) {
    final rawFeed = json['recent_activity_feed'] as List<dynamic>? ?? [];
    final feed = rawFeed
        .map((e) => RecentActivityItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return TeacherOverviewModel(
      totalStudents: json['total_students'] as int? ?? 0,
      activeStudents: json['active_students'] as int? ?? 0,
      avgCourseCompletion: (json['avg_course_completion'] as num?)?.toDouble() ?? 0.0,
      totalSubmissionsToday: json['total_submissions_today'] as int? ?? 0,
      recentActivityFeed: feed,
    );
  }
}

class StudentProgressModel extends StudentProgressEntity {
  const StudentProgressModel({
    required super.studentId,
    required super.studentName,
    required super.studentUsername,
    required super.studentEmail,
    super.studentAvatar,
    required super.coursesEnrolled,
    required super.lessonsCompleted,
    required super.currentStreak,
    super.lastActiveAt,
    required super.overallCompletionPct,
    required super.status,
  });

  factory StudentProgressModel.fromJson(Map<String, dynamic> json) {
    return StudentProgressModel(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String? ?? '',
      studentUsername: json['student_username'] as String? ?? '',
      studentEmail: json['student_email'] as String? ?? '',
      studentAvatar: json['student_avatar'] as String?,
      coursesEnrolled: json['courses_enrolled'] as int? ?? 0,
      lessonsCompleted: json['lessons_completed'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
      overallCompletionPct:
          (json['overall_completion_pct'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'inactive',
    );
  }
}

class BottleneckLessonModel extends BottleneckLessonEntity {
  const BottleneckLessonModel({
    required super.lessonId,
    required super.lessonSlug,
    required super.lessonTitle,
    required super.moduleTitle,
    required super.courseTitle,
    required super.courseSlug,
    required super.contentType,
    required super.totalStudentsEnrolled,
    required super.completionCount,
    required super.completionRate,
    required super.avgAttempts,
    required super.failureRate,
  });

  factory BottleneckLessonModel.fromJson(Map<String, dynamic> json) {
    return BottleneckLessonModel(
      lessonId: json['lesson_id'] as String,
      lessonSlug: json['lesson_slug'] as String? ?? '',
      lessonTitle: json['lesson_title'] as String? ?? '',
      moduleTitle: json['module_title'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      courseSlug: json['course_slug'] as String? ?? '',
      contentType: json['content_type'] as String? ?? 'CONCEPT',
      totalStudentsEnrolled: json['total_students_enrolled'] as int? ?? 0,
      completionCount: json['completion_count'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      avgAttempts: (json['avg_attempts'] as num?)?.toDouble() ?? 0.0,
      failureRate: (json['failure_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ConceptPerformanceModel extends ConceptPerformanceEntity {
  const ConceptPerformanceModel({
    required super.moduleId,
    required super.moduleTitle,
    required super.courseTitle,
    required super.courseSlug,
    required super.totalLessons,
    required super.avgCompletionRate,
    required super.weakLessonCount,
    required super.status,
  });

  factory ConceptPerformanceModel.fromJson(Map<String, dynamic> json) {
    return ConceptPerformanceModel(
      moduleId: json['module_id'] as String,
      moduleTitle: json['module_title'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      courseSlug: json['course_slug'] as String? ?? '',
      totalLessons: json['total_lessons'] as int? ?? 0,
      avgCompletionRate:
          (json['avg_completion_rate'] as num?)?.toDouble() ?? 0.0,
      weakLessonCount: json['weak_lesson_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'weak',
    );
  }
}

class AssignmentModel extends AssignmentEntity {
  const AssignmentModel({
    required super.id,
    required super.teacherId,
    required super.teacherName,
    required super.studentId,
    required super.studentName,
    super.assignmentType = 'LESSON',
    super.lessonId,
    super.lessonSlug,
    super.lessonTitle,
    super.courseTitle,
    super.courseSlug,
    super.customProblemId,
    super.quizId,
    super.title = '',
    required super.assignedAt,
    super.dueDate,
    required super.status,
    super.notes,
    super.completedAt,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String? ?? 'Teacher',
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String? ?? 'Student',
      assignmentType: json['assignment_type'] as String? ?? 'LESSON',
      lessonId: json['lesson_id'] as String?,
      lessonSlug: json['lesson_slug'] as String?,
      lessonTitle: json['lesson_title'] as String?,
      courseTitle: json['course_title'] as String?,
      courseSlug: json['course_slug'] as String?,
      customProblemId: json['custom_problem_id'] as String?,
      quizId: json['quiz_id'] as String?,
      title: json['title'] as String? ?? '',
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}
