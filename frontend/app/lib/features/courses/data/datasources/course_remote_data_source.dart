import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/course_model.dart';

abstract class CourseDataSource {
  Future<List<CourseSummaryModel>> getCourses();
  Future<CourseDetailModel> getCourseDetail(String slug);
  Future<Map<String, dynamic>> enrollInCourse(String slug);
  Future<CourseProgressModel> getCourseProgress(String slug);
  Future<List<CourseProgressModel>> getMyAllProgress();
  Future<Map<String, dynamic>> completeLesson(String lessonId);
  Future<Map<String, dynamic>> recordLessonAccess(String lessonId);
}

class CourseRemoteDataSource implements CourseDataSource {
  @override
  Future<List<CourseSummaryModel>> getCourses() async {
    final token = await TokenStorage.getAccessToken();
    final rawList = await ApiClient.getCourses(accessToken: token);

    return rawList
        .map((item) => CourseSummaryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CourseDetailModel> getCourseDetail(String slug) async {
    final token = await TokenStorage.getAccessToken();
    final json = await ApiClient.getCourseDetail(
      slug: slug,
      accessToken: token,
    );

    return CourseDetailModel.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> enrollInCourse(String slug) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in.');
    }

    return ApiClient.enrollInCourse(
      accessToken: token,
      slug: slug,
    );
  }

  @override
  Future<CourseProgressModel> getCourseProgress(String slug) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in.');
    }

    final json = await ApiClient.getCourseProgress(
      accessToken: token,
      slug: slug,
    );

    return CourseProgressModel.fromJson(json);
  }

  @override
  Future<List<CourseProgressModel>> getMyAllProgress() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return [];
    }

    try {
      final rawList = await ApiClient.getMyAllProgress(accessToken: token);
      return rawList
          .map((item) =>
              CourseProgressModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> completeLesson(String lessonId) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in.');
    }

    return ApiClient.completeLesson(
      accessToken: token,
      lessonId: lessonId,
    );
  }

  @override
  Future<Map<String, dynamic>> recordLessonAccess(String lessonId) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return {};
    }

    try {
      return await ApiClient.recordLessonAccess(
        accessToken: token,
        lessonId: lessonId,
      );
    } catch (_) {
      return {};
    }
  }
}
