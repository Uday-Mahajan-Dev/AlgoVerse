import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/teacher_remote_data_source.dart';
import '../../data/repositories/teacher_repository_impl.dart';
import '../../domain/entities/teacher_entity.dart';
import '../../domain/repositories/teacher_repository.dart';

final teacherDataSourceProvider = Provider<TeacherDataSource>((ref) {
  return TeacherRemoteDataSource();
});

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepositoryImpl(
    dataSource: ref.watch(teacherDataSourceProvider),
  );
});

class TeacherSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final teacherSearchQueryProvider =
    NotifierProvider<TeacherSearchQueryNotifier, String>(
  TeacherSearchQueryNotifier.new,
);

final teachersListProvider = FutureProvider<List<TeacherEntity>>((ref) async {
  final query = ref.watch(teacherSearchQueryProvider);
  final repository = ref.watch(teacherRepositoryProvider);

  return repository.getTeachers(query: query);
});

final teacherProfileProvider =
    FutureProvider.family<TeacherEntity, String>((ref, teacherId) async {
  final repository = ref.watch(teacherRepositoryProvider);

  return repository.getTeacherProfile(teacherId);
});

final myTeacherProvider = FutureProvider<MyTeacherEntity>((ref) async {
  final repository = ref.watch(teacherRepositoryProvider);

  return repository.getMyTeacher();
});

/// Phase 1: All approved mentors for student (multi-professor)
final myMentorsListProvider =
    FutureProvider<List<StudentMentorEntity>>((ref) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) return [];

  final list = await ApiClient.getMyMentors(accessToken: token);
  return list
      .map((item) =>
          StudentMentorEntity.fromJson(item as Map<String, dynamic>))
      .toList();
});

/// Phase 1: Student's outgoing mentorship requests
final studentMentorshipRequestsProvider =
    FutureProvider<List<MentorshipRequestEntity>>((ref) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) return [];

  final list = await ApiClient.getMyMentorshipRequests(accessToken: token);
  return list
      .map((item) =>
          MentorshipRequestEntity.fromJson(item as Map<String, dynamic>))
      .toList();
});

/// Phase 1: Faculty inbox of incoming mentorship requests
final teacherMentorshipRequestsProvider =
    FutureProvider<List<MentorshipRequestEntity>>((ref) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) return [];

  final list = await ApiClient.getTeacherMentorshipRequests(accessToken: token);
  return list
      .map((item) =>
          MentorshipRequestEntity.fromJson(item as Map<String, dynamic>))
      .toList();
});

/// Phase 1: Classroom capacity settings for faculty
final classroomSettingsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) return {};

  return ApiClient.getClassroomSettings(accessToken: token);
});
