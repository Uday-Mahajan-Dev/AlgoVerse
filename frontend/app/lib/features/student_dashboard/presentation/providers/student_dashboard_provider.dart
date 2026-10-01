import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/student_dashboard_remote_data_source.dart';
import '../../data/repositories/student_dashboard_repository_impl.dart';
import '../../domain/entities/student_dashboard_entity.dart';
import '../../domain/repositories/student_dashboard_repository.dart';

final studentDashboardDataSourceProvider =
    Provider<StudentDashboardDataSource>((ref) {
  return StudentDashboardRemoteDataSource();
});

final studentDashboardRepositoryProvider =
    Provider<StudentDashboardRepository>((ref) {
  return StudentDashboardRepositoryImpl(
    dataSource: ref.watch(studentDashboardDataSourceProvider),
  );
});

final studentDashboardProvider =
    FutureProvider<StudentDashboardData>((ref) async {
  final repository = ref.watch(studentDashboardRepositoryProvider);
  return repository.getDashboardData();
});
