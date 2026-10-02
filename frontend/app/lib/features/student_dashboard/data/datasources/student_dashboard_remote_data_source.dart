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
      throw Exception('Not authenticated. Please log in.');
    }

    final json = await ApiClient.getStudentDashboard(token);
    return StudentDashboardModel.fromJson(json);
  }

  @override
  Future<ContinueLearningModel?> getContinueLearning() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    final json = await ApiClient.getContinueLearning(token);
    if (json == null) return null;
    return ContinueLearningModel.fromJson(json);
  }

  @override
  Future<StudentMetricsModel> getStudentMetrics() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in.');
    }

    final json = await ApiClient.getStudentMetrics(token);
    return StudentMetricsModel.fromJson(json);
  }
}

