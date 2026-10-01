import '../entities/problem.dart';

abstract class ProblemRepository {
  Future<ProblemDetail> getProblemForLesson(String lessonSlug);
  Future<TrialResult> runProblemTrial({
    required String problemId,
    required String code,
    required String language,
  });
  Future<SubmissionResult> submitProblemSolution({
    required String problemId,
    required String code,
    required String language,
  });
  Future<List<SubmissionSummary>> getProblemSubmissions(String problemId);
}
