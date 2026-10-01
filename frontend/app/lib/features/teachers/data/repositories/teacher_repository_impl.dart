import '../../domain/entities/teacher_entity.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_remote_data_source.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  final TeacherDataSource dataSource;

  TeacherRepositoryImpl({
    required this.dataSource,
  });

  @override
  Future<List<TeacherEntity>> getTeachers({String? query}) {
    return dataSource.getTeachers(query: query);
  }

  @override
  Future<TeacherEntity> getTeacherProfile(String teacherId) {
    return dataSource.getTeacherProfile(teacherId);
  }

  @override
  Future<Map<String, dynamic>> selectTeacher(String teacherId) {
    return dataSource.selectTeacher(teacherId);
  }

  @override
  Future<MyTeacherEntity> getMyTeacher() {
    return dataSource.getMyTeacher();
  }
}
