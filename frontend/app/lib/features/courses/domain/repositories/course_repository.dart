import '../entities/course_entity.dart';

abstract class CourseRepository {
  Future<List<CourseSummaryEntity>> getCourses();
  Future<CourseDetailEntity> getCourseDetail(String slug);
  Future<Map<String, dynamic>> enrollInCourse(String slug);
  Future<CourseProgressEntity> getCourseProgress(String slug);
  Future<List<CourseProgressEntity>> getMyAllProgress();
  Future<Map<String, dynamic>> completeLesson(String lessonId);
}
