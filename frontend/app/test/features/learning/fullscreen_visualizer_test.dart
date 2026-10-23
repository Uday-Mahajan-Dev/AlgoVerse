import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:algoverse/core/constants/app_routes.dart';
import 'package:algoverse/features/learning/domain/entities/execution_trace.dart';
import 'package:algoverse/features/learning/domain/entities/visualization_step.dart';
import 'package:algoverse/features/learning/presentation/pages/fullscreen_visualizer_page.dart';
import 'package:algoverse/features/learning/presentation/widgets/array_visualizer_widget.dart';
import 'package:algoverse/features/learning/presentation/widgets/interactive_visualizer_workspace.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testTrace = ExecutionTrace(
    algorithmName: 'linearSearch',
    steps: [
      const VisualizationStep(
        stepNumber: 1,
        sourceLine: 2,
        variables: {'i': 0, 'val': 10},
        arrayState: [10, 20, 30, 40],
        pointers: {'i': 0},
        highlights: [0],
        operation: 'COMPARE',
        explanation: 'Checking element at index 0',
      ),
      const VisualizationStep(
        stepNumber: 2,
        sourceLine: 3,
        variables: {'i': 1, 'val': 20},
        arrayState: [10, 20, 30, 40],
        pointers: {'i': 1},
        highlights: [1],
        operation: 'FOUND',
        explanation: 'Found target element at index 1',
      ),
    ],
  );

  final testContentJson = {
    'algorithm_name': 'linearSearch',
    'default_input': {
      'array': [10, 20, 30, 40],
      'target': 20,
    },
    'code_snippets': {
      'python': 'def search(arr, target):\n    for i in range(len(arr)):\n        if arr[i] == target:\n            return i',
    },
    'line_maps': {
      'python': {'1': 1, '2': 2, '3': 3, '4': 4},
    },
  };

  testWidgets('Expand button opens the fullscreen route', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: SingleChildScrollView(
              child: InteractiveVisualizerWorkspace(
                contentJson: testContentJson,
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.visualizeFullscreen,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return FullscreenVisualizerPage(
              trace: extra['trace'] as ExecutionTrace? ?? testTrace,
              algorithm: extra['algorithm']?.toString() ?? 'linearSearch',
              input: extra['input'] as Map<String, dynamic>? ?? {},
              selectedLanguage: extra['selectedLanguage']?.toString() ?? 'python',
              contentJson: extra['contentJson'] as Map<String, dynamic>? ?? testContentJson,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // Verify Expand button exists
    final expandButton = find.byTooltip('Fullscreen Visualizer');
    expect(expandButton, findsOneWidget);

    // Tap Expand button
    await tester.ensureVisible(expandButton);
    await tester.tap(expandButton);
    await tester.pumpAndSettle();

    // Verify FullscreenVisualizerPage is now mounted
    expect(find.byType(FullscreenVisualizerPage), findsOneWidget);
    expect(find.text('Linear Search'), findsOneWidget);
    expect(find.textContaining('Step 1 /'), findsOneWidget);

    // Verify back button works and returns to lesson
    final backButton = find.byTooltip('Back to Lesson');
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.byType(FullscreenVisualizerPage), findsNothing);
    expect(find.byType(InteractiveVisualizerWorkspace), findsOneWidget);
  });

  testWidgets('Fullscreen playback controls: Play advances steps and speed change alters interval', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: FullscreenVisualizerPage(
          trace: testTrace,
          algorithm: 'linearSearch',
          input: const {'array': [10, 20, 30, 40], 'target': 20},
          selectedLanguage: 'python',
          contentJson: testContentJson,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Opens PAUSED at step 0
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.textContaining('Step 1 / 2'), findsOneWidget);

    // Tap Play
    await tester.tap(find.text('PLAY'));
    await tester.pump(); // Start timer
    expect(find.text('PAUSE'), findsOneWidget);

    // Advance 750ms (default 1.0x)
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.textContaining('Step 2 / 2'), findsOneWidget);

    // Reset to step 1
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.textContaining('Step 1 / 2'), findsOneWidget);

    // Open speed menu and choose 2.0x
    final speedButton = find.byTooltip('Playback Speed');
    expect(speedButton, findsOneWidget);
    await tester.tap(speedButton);
    await tester.pumpAndSettle();

    // Select 2.0x Speed
    final twoXItem = find.text('2.0x Speed');
    expect(twoXItem, findsOneWidget);
    await tester.tap(twoXItem);
    await tester.pumpAndSettle();

    // Verify speed text updated to 2.0x
    expect(find.text('2.0x'), findsOneWidget);

    // Play with 2.0x speed -> 750 / 2 = 375ms interval
    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 375));
    expect(find.textContaining('Step 2 / 2'), findsOneWidget);
  });

  testWidgets('Bottom code bar shows only active line and updates per step', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: FullscreenVisualizerPage(
          trace: testTrace,
          algorithm: 'linearSearch',
          input: const {'array': [10, 20, 30, 40], 'target': 20},
          selectedLanguage: 'python',
          contentJson: testContentJson,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1: sourceLine = 2
    expect(find.text('Line 2'), findsOneWidget);
    expect(find.textContaining('for i in range(len(arr)):'), findsOneWidget);
    // Ensure full snippet is NOT displayed in the bottom line box
    expect(find.textContaining('def search'), findsNothing);

    // Step forward to step 2: sourceLine = 3
    final stepForward = find.byTooltip('Step Forward');
    await tester.tap(stepForward);
    await tester.pumpAndSettle();

    expect(find.text('Line 3'), findsOneWidget);
    expect(find.textContaining('if arr[i] == target:'), findsOneWidget);
  });

  testWidgets('Narrow screen (360px) with 40-element array has no RenderFlex overflow and active index scrolled into view', (tester) async {
    // Narrow 360px mobile screen constraint
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fortyElements = List.generate(40, (i) => i * 3);
    final largeTrace = ExecutionTrace(
      algorithmName: 'linearSearch',
      steps: [
        VisualizationStep(
          stepNumber: 1,
          sourceLine: 2,
          variables: {'i': 35, 'val': fortyElements[35]},
          arrayState: fortyElements,
          pointers: {'target_ptr': 35},
          highlights: [35],
          operation: 'COMPARE',
          explanation: 'Comparing element at index 35',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FullscreenVisualizerPage(
          trace: largeTrace,
          algorithm: 'linearSearch',
          input: {'array': fortyElements, 'target': fortyElements[35]},
          selectedLanguage: 'python',
          contentJson: testContentJson,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify NO RenderFlex overflow occurred
    expect(tester.takeException(), isNull);

    // Verify ArrayVisualizerWidget is mounted
    expect(find.byType(ArrayVisualizerWidget), findsOneWidget);

    // Active cell index 35 should be centered/rendered in view
    expect(find.text('[35]'), findsOneWidget);
    expect(find.text('target_ptr'), findsOneWidget);
  });
}
