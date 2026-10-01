import 'package:flutter/foundation.dart';

@immutable
class RecentActivityItemEntity {
  final String studentName;
  final String? studentAvatar;
  final String actionType;
  final String itemTitle;
  final DateTime timestamp;

  const RecentActivityItemEntity({
    required this.studentName,
    this.studentAvatar,
    required this.actionType,
    required this.itemTitle,
    required this.timestamp,
  });
}

@immutable
class TeacherOverviewEntity {
  final int totalStudents;
  final int activeStudents;
  final double avgCourseCompletion;
  final int totalSubmissionsToday;
  final List<RecentActivityItemEntity> recentActivityFeed;

  const TeacherOverviewEntity({
    required this.totalStudents,
    required this.activeStudents,
    required this.avgCourseCompletion,
    required this.totalSubmissionsToday,
    required this.recentActivityFeed,
  });
}

@immutable
class StudentProgressEntity {
  final String studentId;
  final String studentName;
  final String studentUsername;
  final String studentEmail;
  final String? studentAvatar;
  final int coursesEnrolled;
  final int lessonsCompleted;
  final int currentStreak;
  final DateTime? lastActiveAt;
  final double overallCompletionPct;
  final String status; // "active", "at_risk", "inactive"

  const StudentProgressEntity({
    required this.studentId,
    required this.studentName,
    required this.studentUsername,
    required this.studentEmail,
    this.studentAvatar,
    required this.coursesEnrolled,
    required this.lessonsCompleted,
    required this.currentStreak,
    this.lastActiveAt,
    required this.overallCompletionPct,
    required this.status,
  });

  bool get isActive => status == 'active';
  bool get isAtRisk => status == 'at_risk';
  bool get isInactive => status == 'inactive';
}

@immutable
class BottleneckLessonEntity {
  final String lessonId;
  final String lessonSlug;
  final String lessonTitle;
  final String moduleTitle;
  final String courseTitle;
  final String courseSlug;
  final String contentType;
  final int totalStudentsEnrolled;
  final int completionCount;
  final double completionRate;
  final double avgAttempts;
  final double failureRate;

  const BottleneckLessonEntity({
    required this.lessonId,
    required this.lessonSlug,
    required this.lessonTitle,
    required this.moduleTitle,
    required this.courseTitle,
    required this.courseSlug,
    required this.contentType,
    required this.totalStudentsEnrolled,
    required this.completionCount,
    required this.completionRate,
    required this.avgAttempts,
    required this.failureRate,
  });
}

@immutable
class ConceptPerformanceEntity {
  final String moduleId;
  final String moduleTitle;
  final String courseTitle;
  final String courseSlug;
  final int totalLessons;
  final double avgCompletionRate;
  final int weakLessonCount;
  final String status; // "strong", "moderate", "weak"

  const ConceptPerformanceEntity({
    required this.moduleId,
    required this.moduleTitle,
    required this.courseTitle,
    required this.courseSlug,
    required this.totalLessons,
    required this.avgCompletionRate,
    required this.weakLessonCount,
    required this.status,
  });

  bool get isStrong => status == 'strong';
  bool get isModerate => status == 'moderate';
  bool get isWeak => status == 'weak';
}

@immutable
class AssignmentEntity {
  final String id;
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;
  final String lessonId;
  final String lessonSlug;
  final String lessonTitle;
  final String courseTitle;
  final String courseSlug;
  final DateTime assignedAt;
  final DateTime? dueDate;
  final String status; // "pending", "completed", "overdue"
  final String? notes;
  final DateTime? completedAt;

  const AssignmentEntity({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
    required this.lessonId,
    required this.lessonSlug,
    required this.lessonTitle,
    required this.courseTitle,
    required this.courseSlug,
    required this.assignedAt,
    this.dueDate,
    required this.status,
    this.notes,
    this.completedAt,
  });

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isOverdue => status == 'overdue';
}
