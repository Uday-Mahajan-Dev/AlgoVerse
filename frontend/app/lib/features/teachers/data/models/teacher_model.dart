import '../../domain/entities/teacher_entity.dart';

class TeacherModel extends TeacherEntity {
  const TeacherModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.username,
    super.email,
    super.avatarUrl,
    super.bio,
    super.country,
    required super.studentCount,
    required super.specialty,
    super.createdAt,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      try {
        parsedCreatedAt = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }

    return TeacherModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      username: json['username'] as String? ?? 'Teacher',
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      country: json['country'] as String?,
      studentCount: json['student_count'] as int? ?? 0,
      specialty: json['specialty'] as String? ??
          'Data Structures & Competitive Programming',
      createdAt: parsedCreatedAt,
    );
  }
}

class MyTeacherModel extends MyTeacherEntity {
  const MyTeacherModel({
    required super.hasTeacher,
    super.teacher,
    super.selectedAt,
  });

  factory MyTeacherModel.fromJson(Map<String, dynamic> json) {
    final hasTeacher = json['has_teacher'] as bool? ?? false;
    final teacherJson = json['teacher'] as Map<String, dynamic>?;

    DateTime? parsedSelectedAt;
    if (json['selected_at'] != null) {
      try {
        parsedSelectedAt = DateTime.parse(json['selected_at'].toString());
      } catch (_) {}
    }

    return MyTeacherModel(
      hasTeacher: hasTeacher,
      teacher: teacherJson != null ? TeacherModel.fromJson(teacherJson) : null,
      selectedAt: parsedSelectedAt,
    );
  }
}
