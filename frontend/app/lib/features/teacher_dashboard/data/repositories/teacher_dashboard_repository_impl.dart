import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/teacher_dashboard_entity.dart';
import '../datasources/teacher_dashboard_mock_data_source.dart';
import '../models/teacher_dashboard_model.dart';
import '../repositories/teacher_dashboard_repository.dart';

class TeacherDashboardRepositoryImpl implements TeacherDashboardRepository {
  final TeacherDashboardMockDataSource dataSource;

  TeacherDashboardRepositoryImpl({required this.dataSource});

  @override
  Future<TeacherDashboardData> getDashboardData() async {
    final token = await TokenStorage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      try {
        final json = await ApiClient.getTeacherDashboard(token);

        return TeacherDashboardModel.fromJson(json);
      } catch (_) {
        // Fallback to datasource if API call fails
      }
    }

    return dataSource.getDashboardData();
  }
}
