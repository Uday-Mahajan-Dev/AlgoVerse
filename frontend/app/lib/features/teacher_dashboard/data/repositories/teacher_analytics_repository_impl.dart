import '../../domain/entities/teacher_analytics_entity.dart';
import '../../domain/repositories/teacher_analytics_repository.dart';
import '../datasources/teacher_analytics_remote_data_source.dart';

class TeacherAnalyticsRepositoryImpl implements TeacherAnalyticsRepository {
  final TeacherAnalyticsRemoteDataSource _dataSource;

  const TeacherAnalyticsRepositoryImpl(this._dataSource);

  @override
  Future<TeacherOverviewEntity> getOverview() {
    return _dataSource.getOverview();
  }

  @override
  Future<List<StudentProgressEntity>> getStudents() {
    return _dataSource.getStudents();
  }

  @override
  Future<List<BottleneckLessonEntity>> getBottlenecks() {
    return _dataSource.getBottlenecks();
  }

  @override
  Future<List<ConceptPerformanceEntity>> getConcepts() {
    return _dataSource.getConcepts();
  }

  @override
  Future<List<AssignmentEntity>> createAssignment({
    required List<String> studentIds,
    required String lessonId,
    DateTime? dueDate,
    String? notes,
  }) {
    return _dataSource.createAssignment(
      studentIds: studentIds,
      lessonId: lessonId,
      dueDate: dueDate,
      notes: notes,
    );
  }

  @override
  Future<List<AssignmentEntity>> getTeacherAssignments() {
    return _dataSource.getTeacherAssignments();
  }

  @override
  Future<List<AssignmentEntity>> getStudentAssignments() {
    return _dataSource.getStudentAssignments();
  }
}
