import '../../domain/entities/teacher_dashboard_entity.dart';

abstract class TeacherDashboardRepository {
  Future<TeacherDashboardData> getDashboardData();
}