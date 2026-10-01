import '../../domain/entities/problem.dart';
import '../../domain/repositories/problem_repository.dart';
import '../datasources/problem_remote_data_source.dart';

class ProblemRepositoryImpl implements ProblemRepository {
  final ProblemRemoteDataSource _remoteDataSource;

  const ProblemRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProblemDetail> getProblemForLesson(String lessonSlug) {
    return _remoteDataSource.getProblemForLesson(lessonSlug);
  }

  @override
  Future<TrialResult> runProblemTrial({
    required String problemId,
    required String code,
    required String language,
  }) {
    return _remoteDataSource.runProblemTrial(
      problemId: problemId,
      code: code,
      language: language,
    );
  }

  @override
  Future<SubmissionResult> submitProblemSolution({
    required String problemId,
    required String code,
    required String language,
  }) {
    return _remoteDataSource.submitProblemSolution(
      problemId: problemId,
      code: code,
      language: language,
    );
  }

  @override
  Future<List<SubmissionSummary>> getProblemSubmissions(String problemId) {
    return _remoteDataSource.getProblemSubmissions(problemId);
  }
}
