class TeacherEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String? professionalBio;
  final String? country;
  final int studentCount;
  final int maxStudents;
  final bool isAcceptingRequests;
  final bool isVerified;
  final double ratingAvg;
  final int ratingCount;
  final String specialty;
  final String? institutionName;
  final String? designation;
  final String? classCode;
  final String? instagramUrl;
  final String? linkedinUrl;
  final DateTime? createdAt;

  const TeacherEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.email,
    this.avatarUrl,
    this.bio,
    this.professionalBio,
    this.country,
    required this.studentCount,
    this.maxStudents = 100,
    this.isAcceptingRequests = true,
    this.isVerified = true,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    required this.specialty,
    this.institutionName,
    this.designation,
    this.classCode,
    this.instagramUrl,
    this.linkedinUrl,
    this.createdAt,
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : username;
  }

  bool get isAtCapacity => studentCount >= maxStudents;
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

class MentorshipRequestEntity {
  final String id;
  final String studentId;
  final String teacherId;
  final String? classCodeAttempted;
  final String status;
  final String? message;
  final DateTime createdAt;
  final String studentName;
  final String studentUsername;
  final String? studentEmail;
  final String? studentAvatar;
  final String teacherName;
  final String teacherUsername;
  final String? teacherInstitution;
  final String? teacherDesignation;
  final String? teacherAvatar;

  const MentorshipRequestEntity({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.classCodeAttempted,
    required this.status,
    this.message,
    required this.createdAt,
    required this.studentName,
    required this.studentUsername,
    this.studentEmail,
    this.studentAvatar,
    required this.teacherName,
    required this.teacherUsername,
    this.teacherInstitution,
    this.teacherDesignation,
    this.teacherAvatar,
  });

  factory MentorshipRequestEntity.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at'].toString());
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return MentorshipRequestEntity(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString() ?? '',
      classCodeAttempted: json['class_code_attempted']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      message: json['message']?.toString(),
      createdAt: parsedDate,
      studentName: json['student_name']?.toString() ?? 'Student',
      studentUsername: json['student_username']?.toString() ?? '',
      studentEmail: json['student_email']?.toString(),
      studentAvatar: json['student_avatar']?.toString(),
      teacherName: json['teacher_name']?.toString() ?? 'Professor',
      teacherUsername: json['teacher_username']?.toString() ?? '',
      teacherInstitution: json['teacher_institution']?.toString(),
      teacherDesignation: json['teacher_designation']?.toString(),
      teacherAvatar: json['teacher_avatar']?.toString(),
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}

class StudentMentorEntity {
  final String teacherId;
  final String teacherName;
  final String teacherUsername;
  final String? teacherAvatar;
  final String? institutionName;
  final String? designation;
  final String? specialty;
  final String? classCode;
  final DateTime approvedAt;

  const StudentMentorEntity({
    required this.teacherId,
    required this.teacherName,
    required this.teacherUsername,
    this.teacherAvatar,
    this.institutionName,
    this.designation,
    this.specialty,
    this.classCode,
    required this.approvedAt,
  });

  factory StudentMentorEntity.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['approved_at'].toString());
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return StudentMentorEntity(
      teacherId: json['teacher_id']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString() ?? '',
      teacherUsername: json['teacher_username']?.toString() ?? '',
      teacherAvatar: json['teacher_avatar']?.toString(),
      institutionName: json['institution_name']?.toString(),
      designation: json['designation']?.toString(),
      specialty: json['specialty']?.toString(),
      classCode: json['class_code']?.toString(),
      approvedAt: parsedDate,
    );
  }
}
