class VisualizationStep {
  final int stepNumber;
  final int sourceLine;
  final Map<String, dynamic> variables;
  final List<int?> arrayState;
  final Map<String, int> pointers;
  final List<int> highlights;
  final String operation;
  final String explanation;
  final String? result;

  const VisualizationStep({
    required this.stepNumber,
    required this.sourceLine,
    required this.variables,
    required this.arrayState,
    this.pointers = const {},
    this.highlights = const [],
    required this.operation,
    required this.explanation,
    this.result,
  });

  VisualizationStep copyWith({
    int? stepNumber,
    int? sourceLine,
    Map<String, dynamic>? variables,
    List<int?>? arrayState,
    Map<String, int>? pointers,
    List<int>? highlights,
    String? operation,
    String? explanation,
    String? result,
  }) {
    return VisualizationStep(
      stepNumber: stepNumber ?? this.stepNumber,
      sourceLine: sourceLine ?? this.sourceLine,
      variables: variables ?? Map<String, dynamic>.from(this.variables),
      arrayState: arrayState ?? List<int?>.from(this.arrayState),
      pointers: pointers ?? Map<String, int>.from(this.pointers),
      highlights: highlights ?? List<int>.from(this.highlights),
      operation: operation ?? this.operation,
      explanation: explanation ?? this.explanation,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return 'Step $stepNumber (Line $sourceLine) [$operation]: $explanation | Array: $arrayState | Pointers: $pointers | Vars: $variables';
  }
}
