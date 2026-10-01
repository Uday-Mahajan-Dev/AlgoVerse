import 'package:flutter_riverpod/flutter_riverpod.dart';

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
