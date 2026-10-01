import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/course_remote_data_source.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';

final courseDataSourceProvider = Provider<CourseDataSource>((ref) {
  return CourseRemoteDataSource();
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepositoryImpl(
    dataSource: ref.watch(courseDataSourceProvider),
  );
});

class CourseCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';

  void setFilter(String category) {
    state = category;
  }
}

final courseCategoryFilterProvider =
    NotifierProvider<CourseCategoryFilterNotifier, String>(
  CourseCategoryFilterNotifier.new,
);

final coursesListProvider =
    FutureProvider<List<CourseSummaryEntity>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getCourses();
});

final filteredCoursesListProvider =
    Provider<AsyncValue<List<CourseSummaryEntity>>>((ref) {
  final coursesAsync = ref.watch(coursesListProvider);
  final filter = ref.watch(courseCategoryFilterProvider);

  return coursesAsync.whenData((courses) {
    if (filter == 'ALL') return courses;
    return courses
        .where(
          (c) => c.topicCategory.toUpperCase() == filter.toUpperCase(),
        )
        .toList();
  });
});

final courseDetailProvider =
    FutureProvider.family<CourseDetailEntity, String>((ref, slug) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getCourseDetail(slug);
});

final courseProgressProvider =
    FutureProvider.family<CourseProgressEntity, String>((ref, slug) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getCourseProgress(slug);
});

final allStudentProgressProvider =
    FutureProvider<List<CourseProgressEntity>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getMyAllProgress();
});
