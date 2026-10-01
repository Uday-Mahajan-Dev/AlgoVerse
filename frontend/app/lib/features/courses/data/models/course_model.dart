import '../../domain/entities/course_entity.dart';

class LessonModel extends LessonEntity {
  const LessonModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.contentType,
    required super.contentJson,
    required super.orderIndex,
    required super.estimatedMinutes,
    required super.isCompleted,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? 'CONCEPT',
      contentJson: (json['content_json'] is Map)
          ? Map<String, dynamic>.from(json['content_json'] as Map)
          : <String, dynamic>{},
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 10,
      isCompleted: json['is_completed'] == true,
    );
  }
}

class CourseModuleModel extends CourseModuleEntity {
  const CourseModuleModel({
    required super.id,
    required super.title,
    required super.orderIndex,
    required super.lessons,
  });

  factory CourseModuleModel.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'] as List<dynamic>? ?? [];
    return CourseModuleModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      lessons: rawLessons
          .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CourseSummaryModel extends CourseSummaryEntity {
  const CourseSummaryModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.description,
    super.thumbnailUrl,
    required super.difficulty,
    required super.topicCategory,
    required super.moduleCount,
    required super.totalLessons,
    required super.enrollmentCount,
    required super.isEnrolled,
  });

  factory CourseSummaryModel.fromJson(Map<String, dynamic> json) {
    return CourseSummaryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'BEGINNER',
      topicCategory: json['topic_category']?.toString() ?? 'Data Structures',
      moduleCount: (json['module_count'] as num?)?.toInt() ?? 0,
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      enrollmentCount: (json['enrollment_count'] as num?)?.toInt() ?? 0,
      isEnrolled: json['is_enrolled'] == true,
    );
  }
}

class CourseDetailModel extends CourseDetailEntity {
  const CourseDetailModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.description,
    super.thumbnailUrl,
    required super.difficulty,
    required super.topicCategory,
    required super.isPublished,
    required super.moduleCount,
    required super.totalLessons,
    required super.completedLessons,
    required super.completionPercentage,
    required super.enrollmentCount,
    required super.isEnrolled,
    super.enrolledAt,
    required super.modules,
    required super.createdAt,
  });

  factory CourseDetailModel.fromJson(Map<String, dynamic> json) {
    final rawModules = json['modules'] as List<dynamic>? ?? [];
    return CourseDetailModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'BEGINNER',
      topicCategory: json['topic_category']?.toString() ?? 'Data Structures',
      isPublished: json['is_published'] == true,
      moduleCount: (json['module_count'] as num?)?.toInt() ?? 0,
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      completedLessons: (json['completed_lessons'] as num?)?.toInt() ?? 0,
      completionPercentage:
          (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      enrollmentCount: (json['enrollment_count'] as num?)?.toInt() ?? 0,
      isEnrolled: json['is_enrolled'] == true,
      enrolledAt: json['enrolled_at'] != null
          ? DateTime.tryParse(json['enrolled_at'].toString())
          : null,
      modules: rawModules
          .map((e) => CourseModuleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ??
              DateTime.now())
          : DateTime.now(),
    );
  }
}

class CourseProgressModel extends CourseProgressEntity {
  const CourseProgressModel({
    required super.courseId,
    required super.courseTitle,
    required super.courseSlug,
    required super.totalLessons,
    required super.completedLessons,
    required super.completionPercentage,
    super.lastCompletedAt,
  });

  factory CourseProgressModel.fromJson(Map<String, dynamic> json) {
    return CourseProgressModel(
      courseId: json['course_id']?.toString() ?? '',
      courseTitle: json['course_title']?.toString() ?? '',
      courseSlug: json['course_slug']?.toString() ?? '',
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      completedLessons: (json['completed_lessons'] as num?)?.toInt() ?? 0,
      completionPercentage:
          (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      lastCompletedAt: json['last_completed_at'] != null
          ? DateTime.tryParse(json['last_completed_at'].toString())
          : null,
    );
  }
}
