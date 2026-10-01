import 'visualization_step.dart';

class ExecutionTrace {
  final String algorithmName;
  final List<VisualizationStep> steps;
  final dynamic finalResult;

  const ExecutionTrace({
    required this.algorithmName,
    required this.steps,
    this.finalResult,
  });

  int get totalSteps => steps.length;

  bool get isEmpty => steps.isEmpty;
  bool get isNotEmpty => steps.isNotEmpty;

  VisualizationStep? getStep(int index) {
    if (index >= 0 && index < steps.length) {
      return steps[index];
    }
    return null;
  }
}
