import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_data_source.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseDataSource dataSource;

  CourseRepositoryImpl({required this.dataSource});

  @override
  Future<List<CourseSummaryEntity>> getCourses() {
    return dataSource.getCourses();
  }

  @override
  Future<CourseDetailEntity> getCourseDetail(String slug) {
    return dataSource.getCourseDetail(slug);
  }

  @override
  Future<Map<String, dynamic>> enrollInCourse(String slug) {
    return dataSource.enrollInCourse(slug);
  }

  @override
  Future<CourseProgressEntity> getCourseProgress(String slug) {
    return dataSource.getCourseProgress(slug);
  }

  @override
  Future<List<CourseProgressEntity>> getMyAllProgress() {
    return dataSource.getMyAllProgress();
  }

  @override
  Future<Map<String, dynamic>> completeLesson(String lessonId) {
    return dataSource.completeLesson(lessonId);
  }

  @override
  Future<Map<String, dynamic>> recordLessonAccess(String lessonId) {
    return dataSource.recordLessonAccess(lessonId);
  }
}

