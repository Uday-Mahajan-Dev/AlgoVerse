import 'package:flutter/foundation.dart';

@immutable
class PublicTestCase {
  final String id;
  final String stdinInput;
  final String expectedStdout;
  final int orderIndex;

  const PublicTestCase({
    required this.id,
    required this.stdinInput,
    required this.expectedStdout,
    required this.orderIndex,
  });
}

@immutable
class ProblemDetail {
  final String id;
  final String lessonId;
  final String lessonSlug;
  final String title;
  final String description;
  final String functionName;
  final String starterCodePython;
  final String starterCodeJava;
  final String starterCodeCpp;
  final int timeLimitMs;
  final int memoryLimitMb;
  final List<PublicTestCase> publicTestCases;

  const ProblemDetail({
    required this.id,
    required this.lessonId,
    required this.lessonSlug,
    required this.title,
    required this.description,
    required this.functionName,
    required this.starterCodePython,
    required this.starterCodeJava,
    required this.starterCodeCpp,
    required this.timeLimitMs,
    required this.memoryLimitMb,
    required this.publicTestCases,
  });

  String getStarterCode(String language) {
    switch (language.toLowerCase()) {
      case 'java':
        return starterCodeJava;
      case 'cpp':
      case 'c++':
        return starterCodeCpp;
      case 'python':
      default:
        return starterCodePython;
    }
  }
}

@immutable
class TestCaseExecutionResult {
  final int testIndex;
  final bool isHidden;
  final bool passed;
  final String? stdinInput;
  final String? expectedStdout;
  final String? actualOutput;
  final int executionTimeMs;
  final String? errorMessage;

  const TestCaseExecutionResult({
    required this.testIndex,
    required this.isHidden,
    required this.passed,
    this.stdinInput,
    this.expectedStdout,
    this.actualOutput,
    this.executionTimeMs = 0,
    this.errorMessage,
  });
}

@immutable
class TrialResult {
  final String verdict; // AC, WA, TLE, RE, CE, SE
  final int passedCount;
  final int totalCount;
  final int executionTimeMs;
  final int memoryUsedKb;
  final List<TestCaseExecutionResult> testResults;
  final String? compileOutput;

  const TrialResult({
    required this.verdict,
    required this.passedCount,
    required this.totalCount,
    required this.executionTimeMs,
    required this.memoryUsedKb,
    required this.testResults,
    this.compileOutput,
  });

  bool get isAccepted => verdict == 'AC';
}

@immutable
class SubmissionResult {
  final String submissionId;
  final String verdict;
  final int passedCount;
  final int totalCount;
  final int? executionTimeMs;
  final int? memoryUsedKb;
  final int? failedTestIndex;
  final String message;
  final bool isLessonCompleted;

  const SubmissionResult({
    required this.submissionId,
    required this.verdict,
    required this.passedCount,
    required this.totalCount,
    this.executionTimeMs,
    this.memoryUsedKb,
    this.failedTestIndex,
    required this.message,
    this.isLessonCompleted = false,
  });

  bool get isAccepted => verdict == 'AC';
}

@immutable
class SubmissionSummary {
  final String id;
  final String problemId;
  final String language;
  final String verdict;
  final int? executionTimeMs;
  final int? memoryUsedKb;
  final int passedCount;
  final int totalCount;
  final DateTime createdAt;

  const SubmissionSummary({
    required this.id,
    required this.problemId,
    required this.language,
    required this.verdict,
    this.executionTimeMs,
    this.memoryUsedKb,
    required this.passedCount,
    required this.totalCount,
    required this.createdAt,
  });

  bool get isAccepted => verdict == 'AC';
}
