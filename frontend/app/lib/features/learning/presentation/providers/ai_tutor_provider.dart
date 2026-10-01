import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/models/ai_tutor_model.dart';
import '../../domain/entities/ai_tutor_entity.dart';

final aiStatusProvider = FutureProvider<AIStatusEntity>((ref) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) {
    return const AIStatusEntity(
      configured: false,
      provider: 'disabled',
      model: '',
      message: 'Please log in to use the AI tutor.',
    );
  }
  final json = await ApiClient.getAIStatus(accessToken: token);
  return AIStatusModel.fromJson(json);
});

final aiRecommendationsProvider =
    FutureProvider<List<AIRecommendationEntity>>((ref) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) return [];
  final json = await ApiClient.getAIRecommendations(accessToken: token);
  final list = json['recommendations'] as List<dynamic>? ?? [];
  return list
      .map((e) => AIRecommendationModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class AITutorPanelState {
  final bool isLoading;
  final AIHintEntity? currentHint;
  final AIErrorExplanationEntity? currentExplanation;
  final String? errorMessage;
  final int hintsRemaining;

  const AITutorPanelState({
    this.isLoading = false,
    this.currentHint,
    this.currentExplanation,
    this.errorMessage,
    this.hintsRemaining = 10,
  });

  AITutorPanelState copyWith({
    bool? isLoading,
    AIHintEntity? currentHint,
    AIErrorExplanationEntity? currentExplanation,
    String? errorMessage,
    int? hintsRemaining,
    bool clearError = false,
  }) {
    return AITutorPanelState(
      isLoading: isLoading ?? this.isLoading,
      currentHint: currentHint ?? this.currentHint,
      currentExplanation: currentExplanation ?? this.currentExplanation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
    );
  }
}

class AITutorNotifier extends Notifier<AITutorPanelState> {
  @override
  AITutorPanelState build() {
    return const AITutorPanelState();
  }

  Future<void> requestHint({
    required String lessonId,
    required int hintLevel,
    Map<String, dynamic>? visualizationState,
    String? code,
    String? errorInfo,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Authentication required. Please log in.',
        );
        return;
      }

      final json = await ApiClient.getAIHint(
        accessToken: token,
        lessonId: lessonId,
        hintLevel: hintLevel,
        visualizationState: visualizationState,
        code: code,
        errorInfo: errorInfo,
      );

      final hintModel = AIHintModel.fromJson(json);
      state = state.copyWith(
        isLoading: false,
        currentHint: hintModel,
        hintsRemaining: hintModel.hintsRemaining,
        currentExplanation: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> explainError({
    required String submissionId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Authentication required. Please log in.',
        );
        return;
      }

      final json = await ApiClient.explainAIError(
        accessToken: token,
        submissionId: submissionId,
      );

      final explModel = AIErrorExplanationModel.fromJson(json);
      state = state.copyWith(
        isLoading: false,
        currentExplanation: explModel,
        currentHint: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const AITutorPanelState();
  }
}

final aiTutorNotifierProvider =
    NotifierProvider<AITutorNotifier, AITutorPanelState>(
  AITutorNotifier.new,
);
