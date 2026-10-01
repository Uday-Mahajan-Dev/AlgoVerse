import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/problem_models.dart';

abstract class ProblemRemoteDataSource {
  Future<ProblemDetailModel> getProblemForLesson(String lessonSlug);
  Future<TrialResultModel> runProblemTrial({
    required String problemId,
    required String code,
    required String language,
  });
  Future<SubmissionResultModel> submitProblemSolution({
    required String problemId,
    required String code,
    required String language,
  });
  Future<List<SubmissionSummaryModel>> getProblemSubmissions(String problemId);
}

class ProblemRemoteDataSourceImpl implements ProblemRemoteDataSource {
  const ProblemRemoteDataSourceImpl();

  Future<String> _getRequiredToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in.');
    }
    return token;
  }

  @override
  Future<ProblemDetailModel> getProblemForLesson(String lessonSlug) async {
    final token = await _getRequiredToken();
    final res = await ApiClient.getProblemForLesson(
      accessToken: token,
      lessonSlug: lessonSlug,
    );
    return ProblemDetailModel.fromJson(res);
  }

  @override
  Future<TrialResultModel> runProblemTrial({
    required String problemId,
    required String code,
    required String language,
  }) async {
    final token = await _getRequiredToken();
    final res = await ApiClient.runProblemTrial(
      accessToken: token,
      problemId: problemId,
      code: code,
      language: language,
    );
    return TrialResultModel.fromJson(res);
  }

  @override
  Future<SubmissionResultModel> submitProblemSolution({
    required String problemId,
    required String code,
    required String language,
  }) async {
    final token = await _getRequiredToken();
    final res = await ApiClient.submitProblemSolution(
      accessToken: token,
      problemId: problemId,
      code: code,
      language: language,
    );
    return SubmissionResultModel.fromJson(res);
  }

  @override
  Future<List<SubmissionSummaryModel>> getProblemSubmissions(String problemId) async {
    final token = await _getRequiredToken();
    final list = await ApiClient.getProblemSubmissions(
      accessToken: token,
      problemId: problemId,
    );
    return list
        .map((e) => SubmissionSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
