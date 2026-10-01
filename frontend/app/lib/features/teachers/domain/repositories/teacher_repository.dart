import '../entities/teacher_entity.dart';

abstract class TeacherRepository {
  Future<List<TeacherEntity>> getTeachers({String? query});
  Future<TeacherEntity> getTeacherProfile(String teacherId);
  Future<Map<String, dynamic>> selectTeacher(String teacherId);
  Future<MyTeacherEntity> getMyTeacher();
}
