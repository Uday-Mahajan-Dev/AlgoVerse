import '../../domain/entities/teacher_dashboard_entity.dart';
import '../repositories/teacher_dashboard_repository.dart';
import '../datasources/teacher_dashboard_mock_data_source.dart';

class TeacherDashboardRepositoryImpl
    implements TeacherDashboardRepository {
  final TeacherDashboardMockDataSource dataSource;

  TeacherDashboardRepositoryImpl({
    required this.dataSource,
  });

  @override
  Future<TeacherDashboardData> getDashboardData() {
    return dataSource.getDashboardData();
  }
}