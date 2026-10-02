import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/teacher_dashboard_model.dart';

abstract class TeacherDashboardDataSource {
  Future<TeacherDashboardModel> getDashboardData();
}

class TeacherDashboardRemoteDataSource implements TeacherDashboardDataSource {
  @override
  Future<TeacherDashboardModel> getDashboardData() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in.');
    }

    final json = await ApiClient.getTeacherDashboard(token);
    return TeacherDashboardModel.fromJson(json);
  }
}
