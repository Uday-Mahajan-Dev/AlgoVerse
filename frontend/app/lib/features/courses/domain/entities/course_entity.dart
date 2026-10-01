class LessonEntity {
  final String id;
  final String title;
  final String slug;
  final String contentType;
  final Map<String, dynamic> contentJson;
  final int orderIndex;
  final int estimatedMinutes;
  final bool isCompleted;

  const LessonEntity({
    required this.id,
    required this.title,
    required this.slug,
    required this.contentType,
    required this.contentJson,
    required this.orderIndex,
    required this.estimatedMinutes,
    required this.isCompleted,
  });
}

class CourseModuleEntity {
  final String id;
  final String title;
  final int orderIndex;
  final List<LessonEntity> lessons;

  const CourseModuleEntity({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.lessons,
  });
}

class CourseSummaryEntity {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String? thumbnailUrl;
  final String difficulty;
  final String topicCategory;
  final int moduleCount;
  final int totalLessons;
  final int enrollmentCount;
  final bool isEnrolled;

  const CourseSummaryEntity({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    this.thumbnailUrl,
    required this.difficulty,
    required this.topicCategory,
    required this.moduleCount,
    required this.totalLessons,
    required this.enrollmentCount,
    required this.isEnrolled,
  });
}

class CourseDetailEntity {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String? thumbnailUrl;
  final String difficulty;
  final String topicCategory;
  final bool isPublished;
  final int moduleCount;
  final int totalLessons;
  final int completedLessons;
  final double completionPercentage;
  final int enrollmentCount;
  final bool isEnrolled;
  final DateTime? enrolledAt;
  final List<CourseModuleEntity> modules;
  final DateTime createdAt;

  const CourseDetailEntity({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    this.thumbnailUrl,
    required this.difficulty,
    required this.topicCategory,
    required this.isPublished,
    required this.moduleCount,
    required this.totalLessons,
    required this.completedLessons,
    required this.completionPercentage,
    required this.enrollmentCount,
    required this.isEnrolled,
    this.enrolledAt,
    required this.modules,
    required this.createdAt,
  });
}

class CourseProgressEntity {
  final String courseId;
  final String courseTitle;
  final String courseSlug;
  final int totalLessons;
  final int completedLessons;
  final double completionPercentage;
  final DateTime? lastCompletedAt;

  const CourseProgressEntity({
    required this.courseId,
    required this.courseTitle,
    required this.courseSlug,
    required this.totalLessons,
    required this.completedLessons,
    required this.completionPercentage,
    this.lastCompletedAt,
  });
}
