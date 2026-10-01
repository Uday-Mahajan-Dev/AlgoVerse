import '../entities/student_dashboard_entity.dart';

abstract class StudentDashboardRepository {
  Future<StudentDashboardData> getDashboardData();
}
