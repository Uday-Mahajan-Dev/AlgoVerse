import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/teacher_model.dart';

abstract class TeacherDataSource {
  Future<List<TeacherModel>> getTeachers({String? query});
  Future<TeacherModel> getTeacherProfile(String teacherId);
  Future<Map<String, dynamic>> selectTeacher(String teacherId);
  Future<MyTeacherModel> getMyTeacher();
}

class TeacherRemoteDataSource implements TeacherDataSource {
  @override
  Future<List<TeacherModel>> getTeachers({String? query}) async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      return [];
    }

    final rawList = await ApiClient.getTeachers(
      accessToken: token,
      query: query,
    );

    return rawList
        .map((item) => TeacherModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TeacherModel> getTeacherProfile(String teacherId) async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in.');
    }

    final json = await ApiClient.getTeacherProfile(
      accessToken: token,
      teacherId: teacherId,
    );

    return TeacherModel.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> selectTeacher(String teacherId) async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in.');
    }

    return ApiClient.selectTeacher(
      accessToken: token,
      teacherId: teacherId,
    );
  }

  @override
  Future<MyTeacherModel> getMyTeacher() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      return const MyTeacherModel(hasTeacher: false);
    }

    try {
      final json = await ApiClient.getMyTeacher(token);
      return MyTeacherModel.fromJson(json);
    } catch (_) {
      return const MyTeacherModel(hasTeacher: false);
    }
  }
}
