import '../entities/student_dashboard_entity.dart';

abstract class StudentDashboardRepository {
  Future<StudentDashboardData> getDashboardData();
  Future<ContinueLearningEntity?> getContinueLearning();
  Future<StudentMetricsEntity> getStudentMetrics();
}
