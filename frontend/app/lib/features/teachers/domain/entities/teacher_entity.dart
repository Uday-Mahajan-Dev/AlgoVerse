class TeacherEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String? country;
  final int studentCount;
  final String specialty;
  final DateTime? createdAt;

  const TeacherEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.email,
    this.avatarUrl,
    this.bio,
    this.country,
    required this.studentCount,
    required this.specialty,
    this.createdAt,
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : username;
  }
}

class MyTeacherEntity {
  final bool hasTeacher;
  final TeacherEntity? teacher;
  final DateTime? selectedAt;

  const MyTeacherEntity({
    required this.hasTeacher,
    this.teacher,
    this.selectedAt,
  });
}
