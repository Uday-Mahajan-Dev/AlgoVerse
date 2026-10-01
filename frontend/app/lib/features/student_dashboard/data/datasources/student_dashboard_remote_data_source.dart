import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/student_dashboard_model.dart';

abstract class StudentDashboardDataSource {
  Future<StudentDashboardModel> getDashboardData();
}

class StudentDashboardRemoteDataSource implements StudentDashboardDataSource {
  @override
  Future<StudentDashboardModel> getDashboardData() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      // In preview or unauthenticated session, fallback to default model
      return StudentDashboardModel.defaultSample();
    }

    try {
      final json = await ApiClient.getStudentDashboard(token);
      return StudentDashboardModel.fromJson(json);
    } catch (_) {
      // Graceful fallback in development or offline mode
      return StudentDashboardModel.defaultSample();
    }
  }
}
