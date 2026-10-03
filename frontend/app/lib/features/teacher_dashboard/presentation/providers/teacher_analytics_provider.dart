import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/teacher_analytics_remote_data_source.dart';
import '../../data/repositories/teacher_analytics_repository_impl.dart';
import '../../domain/entities/teacher_analytics_entity.dart';
import '../../domain/repositories/teacher_analytics_repository.dart';

final currentUserProfileProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) return {};
  try {
    return await ApiClient.me(token);
  } catch (_) {
    return {};
  }
});

final teacherAnalyticsDataSourceProvider =
    Provider<TeacherAnalyticsRemoteDataSource>((ref) {
  return const TeacherAnalyticsRemoteDataSourceImpl();
});

final teacherAnalyticsRepositoryProvider =
    Provider<TeacherAnalyticsRepository>((ref) {
  final ds = ref.watch(teacherAnalyticsDataSourceProvider);
  return TeacherAnalyticsRepositoryImpl(ds);
});

final teacherOverviewProvider =
    FutureProvider<TeacherOverviewEntity>((ref) async {
  final repo = ref.watch(teacherAnalyticsRepositoryProvider);
  return repo.getOverview();
});

final teacherStudentsProvider =
    FutureProvider<List<StudentProgressEntity>>((ref) async {
  final repo = ref.watch(teacherAnalyticsRepositoryProvider);
  return repo.getStudents();
});

final teacherBottlenecksProvider =
    FutureProvider<List<BottleneckLessonEntity>>((ref) async {
  final repo = ref.watch(teacherAnalyticsRepositoryProvider);
  return repo.getBottlenecks();
});

final teacherConceptsProvider =
    FutureProvider<List<ConceptPerformanceEntity>>((ref) async {
  final repo = ref.watch(teacherAnalyticsRepositoryProvider);
  return repo.getConcepts();
});

final teacherAssignmentsProvider =
    FutureProvider<List<AssignmentEntity>>((ref) async {
  final repo = ref.watch(teacherAnalyticsRepositoryProvider);
  return repo.getTeacherAssignments();
});

final studentAssignmentsProvider =
    FutureProvider<List<AssignmentEntity>>((ref) async {
  final repo = ref.watch(teacherAnalyticsRepositoryProvider);
  return repo.getStudentAssignments();
});

final teacherTARequestsProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) return [];
  try {
    return await ApiClient.getTARequests(accessToken: token);
  } catch (_) {
    return [];
  }
});

final teacherCreatedProblemsProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) return [];
  try {
    return await ApiClient.getTeacherCustomProblems(accessToken: token);
  } catch (_) {
    return [];
  }
});

final teacherCreatedQuizzesProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) return [];
  try {
    return await ApiClient.getTeacherQuizzes(accessToken: token);
  } catch (_) {
    return [];
  }
});


