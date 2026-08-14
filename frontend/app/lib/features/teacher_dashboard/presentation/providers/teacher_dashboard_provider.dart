import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/teacher_dashboard_mock_data_source.dart';
import '../../data/repositories/teacher_dashboard_repository_impl.dart';
import '../../data/repositories/teacher_dashboard_repository.dart';
import '../../domain/entities/teacher_dashboard_entity.dart';

final teacherDashboardDataSourceProvider =
    Provider<TeacherDashboardMockDataSource>((ref) {
  return TeacherDashboardMockDataSource();
});

final teacherDashboardRepositoryProvider =
    Provider<TeacherDashboardRepository>((ref) {
  return TeacherDashboardRepositoryImpl(
    dataSource: ref.watch(teacherDashboardDataSourceProvider),
  );
});

final teacherDashboardProvider =
    FutureProvider<TeacherDashboardData>((ref) async {
  final repository = ref.watch(teacherDashboardRepositoryProvider);

  return repository.getDashboardData();
});