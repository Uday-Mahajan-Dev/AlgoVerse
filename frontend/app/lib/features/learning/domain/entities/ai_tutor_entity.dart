class AIStatusEntity {
  final bool configured;
  final String provider;
  final String model;
  final String message;

  const AIStatusEntity({
    required this.configured,
    required this.provider,
    required this.model,
    required this.message,
  });
}

class AIHintEntity {
  final String hintText;
  final int hintLevel;
  final int hintsRemaining;

  const AIHintEntity({
    required this.hintText,
    required this.hintLevel,
    required this.hintsRemaining,
  });
}

class AIErrorExplanationEntity {
  final String explanation;
  final String? failedTestSummary;

  const AIErrorExplanationEntity({
    required this.explanation,
    this.failedTestSummary,
  });
}

class AIRecommendationEntity {
  final String lessonId;
  final String lessonTitle;
  final String courseTitle;
  final String reason;
  final String priority;

  const AIRecommendationEntity({
    required this.lessonId,
    required this.lessonTitle,
    required this.courseTitle,
    required this.reason,
    required this.priority,
  });
}
