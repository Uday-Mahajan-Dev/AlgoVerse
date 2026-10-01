import '../../domain/entities/problem.dart';

class PublicTestCaseModel extends PublicTestCase {
  const PublicTestCaseModel({
    required super.id,
    required super.stdinInput,
    required super.expectedStdout,
    required super.orderIndex,
  });

  factory PublicTestCaseModel.fromJson(Map<String, dynamic> json) {
    return PublicTestCaseModel(
      id: json['id'] as String,
      stdinInput: json['stdin_input'] as String? ?? '',
      expectedStdout: json['expected_stdout'] as String? ?? '',
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }
}

class ProblemDetailModel extends ProblemDetail {
  const ProblemDetailModel({
    required super.id,
    required super.lessonId,
    required super.lessonSlug,
    required super.title,
    required super.description,
    required super.functionName,
    required super.starterCodePython,
    required super.starterCodeJava,
    required super.starterCodeCpp,
    required super.timeLimitMs,
    required super.memoryLimitMb,
    required super.publicTestCases,
  });

  factory ProblemDetailModel.fromJson(Map<String, dynamic> json) {
    final rawCases = json['public_test_cases'] as List<dynamic>? ?? [];
    final cases = rawCases
        .map((e) => PublicTestCaseModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProblemDetailModel(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      lessonSlug: json['lesson_slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      functionName: json['function_name'] as String? ?? '',
      starterCodePython: json['starter_code_python'] as String? ?? '',
      starterCodeJava: json['starter_code_java'] as String? ?? '',
      starterCodeCpp: json['starter_code_cpp'] as String? ?? '',
      timeLimitMs: json['time_limit_ms'] as int? ?? 2000,
      memoryLimitMb: json['memory_limit_mb'] as int? ?? 64,
      publicTestCases: cases,
    );
  }
}

class TestCaseExecutionResultModel extends TestCaseExecutionResult {
  const TestCaseExecutionResultModel({
    required super.testIndex,
    required super.isHidden,
    required super.passed,
    super.stdinInput,
    super.expectedStdout,
    super.actualOutput,
    super.executionTimeMs,
    super.errorMessage,
  });

  factory TestCaseExecutionResultModel.fromJson(Map<String, dynamic> json) {
    return TestCaseExecutionResultModel(
      testIndex: json['test_index'] as int? ?? 0,
      isHidden: json['is_hidden'] as bool? ?? false,
      passed: json['passed'] as bool? ?? false,
      stdinInput: json['stdin_input'] as String?,
      expectedStdout: json['expected_stdout'] as String?,
      actualOutput: json['actual_output'] as String?,
      executionTimeMs: json['execution_time_ms'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
    );
  }
}

class TrialResultModel extends TrialResult {
  const TrialResultModel({
    required super.verdict,
    required super.passedCount,
    required super.totalCount,
    required super.executionTimeMs,
    required super.memoryUsedKb,
    required super.testResults,
    super.compileOutput,
  });

  factory TrialResultModel.fromJson(Map<String, dynamic> json) {
    final rawResults = json['test_results'] as List<dynamic>? ?? [];
    final results = rawResults
        .map((e) => TestCaseExecutionResultModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return TrialResultModel(
      verdict: json['verdict'] as String? ?? 'SE',
      passedCount: json['passed_count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
      executionTimeMs: json['execution_time_ms'] as int? ?? 0,
      memoryUsedKb: json['memory_used_kb'] as int? ?? 0,
      testResults: results,
      compileOutput: json['compile_output'] as String?,
    );
  }
}

class SubmissionResultModel extends SubmissionResult {
  const SubmissionResultModel({
    required super.submissionId,
    required super.verdict,
    required super.passedCount,
    required super.totalCount,
    super.executionTimeMs,
    super.memoryUsedKb,
    super.failedTestIndex,
    required super.message,
    super.isLessonCompleted,
  });

  factory SubmissionResultModel.fromJson(Map<String, dynamic> json) {
    return SubmissionResultModel(
      submissionId: json['submission_id'] as String? ?? '',
      verdict: json['verdict'] as String? ?? 'SE',
      passedCount: json['passed_count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
      executionTimeMs: json['execution_time_ms'] as int?,
      memoryUsedKb: json['memory_used_kb'] as int?,
      failedTestIndex: json['failed_test_index'] as int?,
      message: json['message'] as String? ?? '',
      isLessonCompleted: json['is_lesson_completed'] as bool? ?? false,
    );
  }
}

class SubmissionSummaryModel extends SubmissionSummary {
  const SubmissionSummaryModel({
    required super.id,
    required super.problemId,
    required super.language,
    required super.verdict,
    super.executionTimeMs,
    super.memoryUsedKb,
    required super.passedCount,
    required super.totalCount,
    required super.createdAt,
  });

  factory SubmissionSummaryModel.fromJson(Map<String, dynamic> json) {
    return SubmissionSummaryModel(
      id: json['id'] as String,
      problemId: json['problem_id'] as String,
      language: json['language'] as String? ?? 'python',
      verdict: json['verdict'] as String? ?? 'SE',
      executionTimeMs: json['execution_time_ms'] as int?,
      memoryUsedKb: json['memory_used_kb'] as int?,
      passedCount: json['passed_count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
