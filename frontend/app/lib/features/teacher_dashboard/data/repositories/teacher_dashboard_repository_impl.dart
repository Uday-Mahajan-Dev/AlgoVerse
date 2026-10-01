import '../../domain/entities/teacher_dashboard_entity.dart';
import '../datasources/teacher_dashboard_remote_data_source.dart';
import '../repositories/teacher_dashboard_repository.dart';

class TeacherDashboardRepositoryImpl
    implements TeacherDashboardRepository {
  final TeacherDashboardDataSource dataSource;

  TeacherDashboardRepositoryImpl({
    required this.dataSource,
  });

  @override
  Future<TeacherDashboardData> getDashboardData() {
    return dataSource.getDashboardData();
  }
}