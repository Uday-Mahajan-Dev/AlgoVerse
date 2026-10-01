import '../../domain/entities/student_dashboard_entity.dart';
import '../../domain/repositories/student_dashboard_repository.dart';
import '../datasources/student_dashboard_remote_data_source.dart';

class StudentDashboardRepositoryImpl implements StudentDashboardRepository {
  final StudentDashboardDataSource dataSource;

  StudentDashboardRepositoryImpl({
    required this.dataSource,
  });

  @override
  Future<StudentDashboardData> getDashboardData() {
    return dataSource.getDashboardData();
  }

  @override
  Future<ContinueLearningEntity?> getContinueLearning() {
    return dataSource.getContinueLearning();
  }

  @override
  Future<StudentMetricsEntity> getStudentMetrics() {
    return dataSource.getStudentMetrics();
  }
}
