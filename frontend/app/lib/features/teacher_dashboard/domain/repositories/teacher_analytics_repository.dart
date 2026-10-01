import '../entities/teacher_analytics_entity.dart';

abstract class TeacherAnalyticsRepository {
  Future<TeacherOverviewEntity> getOverview();
  Future<List<StudentProgressEntity>> getStudents();
  Future<List<BottleneckLessonEntity>> getBottlenecks();
  Future<List<ConceptPerformanceEntity>> getConcepts();
  Future<List<AssignmentEntity>> createAssignment({
    required List<String> studentIds,
    required String lessonId,
    DateTime? dueDate,
    String? notes,
  });
  Future<List<AssignmentEntity>> getTeacherAssignments();
  Future<List<AssignmentEntity>> getStudentAssignments();
}
