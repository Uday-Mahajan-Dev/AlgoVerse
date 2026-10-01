import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/teacher_analytics_model.dart';

abstract class TeacherAnalyticsRemoteDataSource {
  Future<TeacherOverviewModel> getOverview();
  Future<List<StudentProgressModel>> getStudents();
  Future<List<BottleneckLessonModel>> getBottlenecks();
  Future<List<ConceptPerformanceModel>> getConcepts();
  Future<List<AssignmentModel>> createAssignment({
    required List<String> studentIds,
    required String lessonId,
    DateTime? dueDate,
    String? notes,
  });
  Future<List<AssignmentModel>> getTeacherAssignments();
  Future<List<AssignmentModel>> getStudentAssignments();
}

class TeacherAnalyticsRemoteDataSourceImpl
    implements TeacherAnalyticsRemoteDataSource {
  const TeacherAnalyticsRemoteDataSourceImpl();

  Future<String> _getRequiredToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in.');
    }
    return token;
  }

  @override
  Future<TeacherOverviewModel> getOverview() async {
    final token = await _getRequiredToken();
    final json = await ApiClient.getTeacherAnalyticsOverview(accessToken: token);
    return TeacherOverviewModel.fromJson(json);
  }

  @override
  Future<List<StudentProgressModel>> getStudents() async {
    final token = await _getRequiredToken();
    final list = await ApiClient.getTeacherAnalyticsStudents(accessToken: token);
    return list
        .map((e) => StudentProgressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BottleneckLessonModel>> getBottlenecks() async {
    final token = await _getRequiredToken();
    final list =
        await ApiClient.getTeacherAnalyticsBottlenecks(accessToken: token);
    return list
        .map((e) => BottleneckLessonModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ConceptPerformanceModel>> getConcepts() async {
    final token = await _getRequiredToken();
    final list = await ApiClient.getTeacherAnalyticsConcepts(accessToken: token);
    return list
        .map((e) => ConceptPerformanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AssignmentModel>> createAssignment({
    required List<String> studentIds,
    required String lessonId,
    DateTime? dueDate,
    String? notes,
  }) async {
    final token = await _getRequiredToken();
    final list = await ApiClient.createTeacherAssignment(
      accessToken: token,
      studentIds: studentIds,
      lessonId: lessonId,
      dueDate: dueDate,
      notes: notes,
    );
    return list
        .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AssignmentModel>> getTeacherAssignments() async {
    final token = await _getRequiredToken();
    final list = await ApiClient.getTeacherAssignments(accessToken: token);
    return list
        .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AssignmentModel>> getStudentAssignments() async {
    final token = await _getRequiredToken();
    final list = await ApiClient.getStudentAssignments(accessToken: token);
    return list
        .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
