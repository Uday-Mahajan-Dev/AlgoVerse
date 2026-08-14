import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:algoverse/app/app.dart';

void main() {
  testWidgets('AlgoVerse app starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AlgoVerseApp()));

    // Allow the splash screen's 2-second timer to complete.
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(AlgoVerseApp), findsOneWidget);
  });
}
