import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:algoverse/app/app.dart';

void main() {
  testWidgets('AlgoVerse app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AlgoVerseApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AlgoVerseApp), findsOneWidget);
  });
}