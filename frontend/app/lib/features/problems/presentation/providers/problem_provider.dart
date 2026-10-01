import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/problem_remote_data_source.dart';
import '../../data/repositories/problem_repository_impl.dart';
import '../../domain/entities/problem.dart';
import '../../domain/repositories/problem_repository.dart';

// Repositories & Data Source Providers
final problemRemoteDataSourceProvider = Provider<ProblemRemoteDataSource>((ref) {
  return const ProblemRemoteDataSourceImpl();
});

final problemRepositoryProvider = Provider<ProblemRepository>((ref) {
  final ds = ref.watch(problemRemoteDataSourceProvider);
  return ProblemRepositoryImpl(ds);
});

@immutable
class ProblemState {
  final AsyncValue<ProblemDetail> problemDetail;
  final String selectedLanguage; // "python", "java", "cpp"
  final Map<String, String> codeBuffers;
  final bool isRunning;
  final bool isSubmitting;
  final TrialResult? trialResult;
  final SubmissionResult? submissionResult;
  final String? activeErrorMessage;
  final int selectedTestTabIndex;
  final AsyncValue<List<SubmissionSummary>> submissions;

  const ProblemState({
    required this.problemDetail,
    this.selectedLanguage = 'python',
    this.codeBuffers = const {},
    this.isRunning = false,
    this.isSubmitting = false,
    this.trialResult,
    this.submissionResult,
    this.activeErrorMessage,
    this.selectedTestTabIndex = 0,
    this.submissions = const AsyncValue.data([]),
  });

  String get currentCode {
    if (codeBuffers.containsKey(selectedLanguage)) {
      return codeBuffers[selectedLanguage]!;
    }
    return problemDetail.value?.getStarterCode(selectedLanguage) ?? '';
  }

  ProblemState copyWith({
    AsyncValue<ProblemDetail>? problemDetail,
    String? selectedLanguage,
    Map<String, String>? codeBuffers,
    bool? isRunning,
    bool? isSubmitting,
    TrialResult? trialResult,
    SubmissionResult? submissionResult,
    String? activeErrorMessage,
    int? selectedTestTabIndex,
    AsyncValue<List<SubmissionSummary>>? submissions,
    bool clearTrial = false,
    bool clearSubmission = false,
    bool clearError = false,
  }) {
    return ProblemState(
      problemDetail: problemDetail ?? this.problemDetail,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      codeBuffers: codeBuffers ?? this.codeBuffers,
      isRunning: isRunning ?? this.isRunning,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      trialResult: clearTrial ? null : (trialResult ?? this.trialResult),
      submissionResult:
          clearSubmission ? null : (submissionResult ?? this.submissionResult),
      activeErrorMessage:
          clearError ? null : (activeErrorMessage ?? this.activeErrorMessage),
      selectedTestTabIndex:
          selectedTestTabIndex ?? this.selectedTestTabIndex,
      submissions: submissions ?? this.submissions,
    );
  }
}

class ProblemNotifier extends StateNotifier<ProblemState> {
  final ProblemRepository _repository;
  final String lessonSlug;

  ProblemNotifier(this._repository, this.lessonSlug)
      : super(const ProblemState(problemDetail: AsyncValue.loading())) {
    loadProblem();
  }

  Future<void> loadProblem() async {
    state = state.copyWith(problemDetail: const AsyncValue.loading());
    try {
      final problem = await _repository.getProblemForLesson(lessonSlug);
      final initialBuffers = <String, String>{
        'python': problem.starterCodePython,
        'java': problem.starterCodeJava,
        'cpp': problem.starterCodeCpp,
      };

      state = state.copyWith(
        problemDetail: AsyncValue.data(problem),
        codeBuffers: initialBuffers,
        selectedLanguage: 'python',
        clearTrial: true,
        clearSubmission: true,
        clearError: true,
      );

      loadSubmissions(problem.id);
    } catch (e, st) {
      state = state.copyWith(
        problemDetail: AsyncValue.error(e, st),
      );
    }
  }

  void selectLanguage(String language) {
    final langKey = language.toLowerCase();
    if (state.selectedLanguage == langKey) return;

    final buffers = Map<String, String>.from(state.codeBuffers);
    final detail = state.problemDetail.value;
    if (detail != null && !buffers.containsKey(langKey)) {
      buffers[langKey] = detail.getStarterCode(langKey);
    }

    state = state.copyWith(
      selectedLanguage: langKey,
      codeBuffers: buffers,
      clearError: true,
    );
  }

  void updateCode(String code) {
    final buffers = Map<String, String>.from(state.codeBuffers);
    buffers[state.selectedLanguage] = code;
    state = state.copyWith(codeBuffers: buffers);
  }

  void resetCurrentCode() {
    final detail = state.problemDetail.value;
    if (detail == null) return;

    final starter = detail.getStarterCode(state.selectedLanguage);
    final buffers = Map<String, String>.from(state.codeBuffers);
    buffers[state.selectedLanguage] = starter;
    state = state.copyWith(
      codeBuffers: buffers,
      clearTrial: true,
      clearSubmission: true,
      clearError: true,
    );
  }

  void selectTestTab(int index) {
    state = state.copyWith(selectedTestTabIndex: index);
  }

  Future<void> runTrial() async {
    final detail = state.problemDetail.value;
    if (detail == null) return;

    state = state.copyWith(
      isRunning: true,
      clearTrial: true,
      clearSubmission: true,
      clearError: true,
    );

    try {
      final result = await _repository.runProblemTrial(
        problemId: detail.id,
        code: state.currentCode,
        language: state.selectedLanguage,
      );

      state = state.copyWith(
        isRunning: false,
        trialResult: result,
        selectedTestTabIndex: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        activeErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<SubmissionResult?> submitSolution({
    VoidCallback? onAccepted,
  }) async {
    final detail = state.problemDetail.value;
    if (detail == null) return null;

    state = state.copyWith(
      isSubmitting: true,
      clearTrial: true,
      clearSubmission: true,
      clearError: true,
    );

    try {
      final result = await _repository.submitProblemSolution(
        problemId: detail.id,
        code: state.currentCode,
        language: state.selectedLanguage,
      );

      state = state.copyWith(
        isSubmitting: false,
        submissionResult: result,
      );

      // Refresh submissions history
      loadSubmissions(detail.id);

      if (result.isAccepted) {
        onAccepted?.call();
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        activeErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<void> loadSubmissions(String problemId) async {
    state = state.copyWith(submissions: const AsyncValue.loading());
    try {
      final list = await _repository.getProblemSubmissions(problemId);
      state = state.copyWith(submissions: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(submissions: AsyncValue.error(e, st));
    }
  }
}

final problemProvider =
    StateNotifierProvider.family<ProblemNotifier, ProblemState, String>(
  (ref, lessonSlug) {
    final repo = ref.watch(problemRepositoryProvider);
    return ProblemNotifier(repo, lessonSlug);
  },
);
