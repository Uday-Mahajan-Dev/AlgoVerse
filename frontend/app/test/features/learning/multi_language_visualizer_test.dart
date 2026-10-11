import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algoverse/features/learning/presentation/widgets/interactive_visualizer_workspace.dart';
import 'package:algoverse/features/learning/presentation/widgets/code_viewer_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Lesson with only python has no language toggle rendered', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final singleLanguageContent = {
      'algorithm_name': 'linearSearch',
      'default_input': {'array': [1, 2, 3], 'target': 2},
      'code_snippet': 'def linear_search(arr, target):\n    pass',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InteractiveVisualizerWorkspace(
              contentJson: singleLanguageContent,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Language:" toggle header is NOT rendered
    expect(find.text('Language:'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);

    // Verify python snippet is shown
    expect(find.byType(CodeViewerWidget), findsOneWidget);
    expect(find.textContaining('def linear_search'), findsOneWidget);
  });

  testWidgets('Lesson with 3 languages shows toggles and switches snippet while keeping tracer intact', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final multiLanguageContent = {
      'algorithm_name': 'linearSearch',
      'default_input': {'array': [1, 2, 3], 'target': 2},
      'code_snippets': {
        'python': 'def linear_search(arr, target):\n    for i in arr:\n        return i',
        'java': 'int linearSearch(int[] arr, int target) {\n    return -1;\n}',
        'cpp': 'int linearSearch(vector<int>& arr, int target) {\n    return 0;\n}',
      },
      'line_maps': {
        'python': {'1': 1, '2': 2, '3': 3},
        'java': {'1': 1, '2': 2},
      },
      'default_language': 'python',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InteractiveVisualizerWorkspace(
              contentJson: multiLanguageContent,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Language:" label is rendered
    expect(find.text('Language:'), findsOneWidget);

    // Verify 3 language chips are present
    expect(find.text('Python'), findsOneWidget);
    expect(find.text('Java'), findsOneWidget);
    expect(find.text('C++'), findsOneWidget);

    // Initially Python code is visible
    expect(find.textContaining('def linear_search'), findsOneWidget);
    expect(find.textContaining('int linearSearch(int[] arr'), findsNothing);

    // Tap Java chip
    await tester.tap(find.text('Java'));
    await tester.pumpAndSettle();

    // Verify snippet switched to Java
    expect(find.textContaining('int linearSearch(int[] arr'), findsOneWidget);
    expect(find.textContaining('def linear_search'), findsNothing);

    // Verify tracer step controls are still present and unaffected
    expect(find.textContaining('Step 1 /'), findsOneWidget);

    // Tap C++ chip
    await tester.tap(find.text('C++'));
    await tester.pumpAndSettle();

    // Verify snippet switched to C++
    expect(find.textContaining('vector<int>& arr'), findsOneWidget);
    expect(find.textContaining('int linearSearch(int[] arr'), findsNothing);
  });
}
