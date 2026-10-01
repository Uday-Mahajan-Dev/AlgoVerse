import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/teacher_dashboard_model.dart';
import 'teacher_dashboard_mock_data_source.dart';

abstract class TeacherDashboardDataSource {
  Future<TeacherDashboardModel> getDashboardData();
}

class TeacherDashboardRemoteDataSource implements TeacherDashboardDataSource {
  final TeacherDashboardMockDataSource _fallbackMockDataSource =
      TeacherDashboardMockDataSource();

  @override
  Future<TeacherDashboardModel> getDashboardData() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      // If no auth token is found in preview/test mode, fallback to mock data
      return _fallbackMockDataSource.getDashboardData();
    }

    try {
      final json = await ApiClient.getTeacherDashboard(token);
      return TeacherDashboardModel.fromJson(json);
    } catch (_) {
      // In development or when offline, fallback gracefully to mock data
      return _fallbackMockDataSource.getDashboardData();
    }
  }
}
