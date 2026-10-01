import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/student_dashboard_model.dart';

abstract class StudentDashboardDataSource {
  Future<StudentDashboardModel> getDashboardData();
  Future<ContinueLearningModel?> getContinueLearning();
  Future<StudentMetricsModel> getStudentMetrics();
}

class StudentDashboardRemoteDataSource implements StudentDashboardDataSource {
  @override
  Future<StudentDashboardModel> getDashboardData() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      return StudentDashboardModel.defaultSample();
    }

    try {
      final json = await ApiClient.getStudentDashboard(token);
      return StudentDashboardModel.fromJson(json);
    } catch (_) {
      return StudentDashboardModel.defaultSample();
    }
  }

  @override
  Future<ContinueLearningModel?> getContinueLearning() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final json = await ApiClient.getContinueLearning(token);
      if (json == null) return null;
      return ContinueLearningModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StudentMetricsModel> getStudentMetrics() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      return const StudentMetricsModel(
        totalCoursesEnrolled: 0,
        totalLessonsCompleted: 0,
        totalVisualizationsCompleted: 0,
        totalProblemsSolved: 0,
        currentStreak: 0,
      );
    }

    try {
      final json = await ApiClient.getStudentMetrics(token);
      return StudentMetricsModel.fromJson(json);
    } catch (_) {
      return const StudentMetricsModel(
        totalCoursesEnrolled: 0,
        totalLessonsCompleted: 0,
        totalVisualizationsCompleted: 0,
        totalProblemsSolved: 0,
        currentStreak: 0,
      );
    }
  }
}
