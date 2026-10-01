import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

class ApiClient {
  ApiClient._();

  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  static Future<Map<String, dynamic>> _handleResponse(
    http.Response response,
  ) async {
    Map<String, dynamic> body = {};

    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = {};
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['detail']?.toString() ?? 'Something went wrong. Please try again.',
      );
    }

    return body;
  }

  static Future<List<dynamic>> _handleListResponse(
    http.Response response,
  ) async {
    List<dynamic> list = [];

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          list = decoded;
        }
      } catch (_) {
        list = [];
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Something went wrong. Please try again.');
    }

    return list;
  }

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
            'first_name': firstName,
            'last_name': lastName,
          }),
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  // ============================================================
  // VERIFY EMAIL
  // ============================================================

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/verify-email'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'otp': otp}),
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  // ============================================================
  // RESEND VERIFICATION
  // ============================================================

  static Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/resend-verification'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  // ============================================================
  // EMAIL LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  // ============================================================
  // GOOGLE / GITHUB FIREBASE LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> socialLogin(
    String firebaseIdToken,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/social-login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_token': firebaseIdToken}),
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  static Future<Map<String, dynamic>> me(String accessToken) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/auth/me'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  // ============================================================
  // REFRESH
  // ============================================================

  static Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  // ============================================================
  // DASHBOARDS
  // ============================================================

  static Future<Map<String, dynamic>> getStudentDashboard(
    String accessToken,
  ) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/dashboard/student'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTeacherDashboard(
    String accessToken,
  ) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/dashboard/teacher'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  // ============================================================
  // TEACHERS
  // ============================================================

  static Future<List<dynamic>> getTeachers({
    required String accessToken,
    String? query,
  }) async {
    final uri = Uri.parse(
      query != null && query.trim().isNotEmpty
          ? '$baseUrl/teachers?q=${Uri.encodeComponent(query.trim())}'
          : '$baseUrl/teachers',
    );

    final response = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(AppConstants.requestTimeout);

    return _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> getMyTeacher(
    String accessToken,
  ) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/teachers/my-teacher'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTeacherProfile({
    required String accessToken,
    required String teacherId,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/teachers/$teacherId'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> selectTeacher({
    required String accessToken,
    required String teacherId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/teachers/$teacherId/select'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  // ============================================================
  // COURSES & LESSONS
  // ============================================================

  static Future<List<dynamic>> getCourses({String? accessToken}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await http
        .get(
          Uri.parse('$baseUrl/courses'),
          headers: headers,
        )
        .timeout(AppConstants.requestTimeout);

    return _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> getCourseDetail({
    required String slug,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await http
        .get(
          Uri.parse('$baseUrl/courses/$slug'),
          headers: headers,
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> enrollInCourse({
    required String accessToken,
    required String slug,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/courses/$slug/enroll'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCourseProgress({
    required String accessToken,
    required String slug,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/courses/$slug/progress'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getMyAllProgress({
    required String accessToken,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/courses/my-progress'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(AppConstants.requestTimeout);

    return _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> completeLesson({
    required String accessToken,
    required String lessonId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/lessons/$lessonId/complete'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse(response);
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout(String refreshToken) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(AppConstants.requestTimeout);

    await _handleResponse(response);
  }
}

