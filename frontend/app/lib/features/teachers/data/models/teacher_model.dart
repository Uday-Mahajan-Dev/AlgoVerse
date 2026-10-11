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
    super.professionalBio,
    super.country,
    required super.studentCount,
    super.maxStudents = 100,
    super.isAcceptingRequests = true,
    super.isVerified = true,
    super.ratingAvg = 0.0,
    super.ratingCount = 0,
    required super.specialty,
    super.institutionName,
    super.designation,
    super.classCode,
    super.instagramUrl,
    super.linkedinUrl,
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
      professionalBio: (json['professional_bio'] ?? json['bio']) as String?,
      country: json['country'] as String?,
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
      maxStudents: (json['max_students'] as num?)?.toInt() ?? 100,
      isAcceptingRequests: json['is_accepting_requests'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? true,
      ratingAvg: ((json['avg_rating'] ?? json['rating_avg']) as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      specialty: json['specialty'] as String? ??
          'Data Structures & Competitive Programming',
      institutionName: json['institution_name'] as String?,
      designation: json['designation'] as String?,
      classCode: json['class_code'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
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
    TeacherModel? teacher;

    if (hasTeacher && json['teacher'] != null) {
      teacher = TeacherModel.fromJson(json['teacher'] as Map<String, dynamic>);
    }

    DateTime? parsedSelectedAt;
    if (json['selected_at'] != null) {
      try {
        parsedSelectedAt = DateTime.parse(json['selected_at'].toString());
      } catch (_) {}
    }

    return MyTeacherModel(
      hasTeacher: hasTeacher,
      teacher: teacher,
      selectedAt: parsedSelectedAt,
    );
  }
}
