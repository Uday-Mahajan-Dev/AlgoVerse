import '../../domain/entities/ai_tutor_entity.dart';

class AIStatusModel extends AIStatusEntity {
  const AIStatusModel({
    required super.configured,
    required super.provider,
    required super.model,
    required super.message,
  });

  factory AIStatusModel.fromJson(Map<String, dynamic> json) {
    return AIStatusModel(
      configured: json['configured'] as bool? ?? false,
      provider: json['provider'] as String? ?? 'disabled',
      model: json['model'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

class AIHintModel extends AIHintEntity {
  const AIHintModel({
    required super.hintText,
    required super.hintLevel,
    required super.hintsRemaining,
  });

  factory AIHintModel.fromJson(Map<String, dynamic> json) {
    return AIHintModel(
      hintText: json['hint_text'] as String? ?? '',
      hintLevel: json['hint_level'] as int? ?? 1,
      hintsRemaining: json['hints_remaining'] as int? ?? 10,
    );
  }
}

class AIErrorExplanationModel extends AIErrorExplanationEntity {
  const AIErrorExplanationModel({
    required super.explanation,
    super.failedTestSummary,
  });

  factory AIErrorExplanationModel.fromJson(Map<String, dynamic> json) {
    return AIErrorExplanationModel(
      explanation: json['explanation'] as String? ?? '',
      failedTestSummary: json['failed_test_summary'] as String?,
    );
  }
}

class AIRecommendationModel extends AIRecommendationEntity {
  const AIRecommendationModel({
    required super.lessonId,
    required super.lessonTitle,
    required super.courseTitle,
    required super.reason,
    required super.priority,
  });

  factory AIRecommendationModel.fromJson(Map<String, dynamic> json) {
    return AIRecommendationModel(
      lessonId: json['lesson_id'] as String? ?? '',
      lessonTitle: json['lesson_title'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
    );
  }
}
