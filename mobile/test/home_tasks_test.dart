import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datamint_mobile/features/home/home_tab.dart';
import 'package:datamint_mobile/features/tasks/tasks_screen.dart';

void main() {
  testWidgets('HomeTab renders balance, stats and quick tasks', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HomeTab(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amina'), findsOneWidget);
    expect(find.text('Tasks for you'), findsOneWidget);
    expect(find.text('Cash out'), findsOneWidget);
  });

  testWidgets('TasksScreen renders category filters and task items', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TasksScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('All 24'), findsOneWidget);
    expect(find.text('Voice 12'), findsOneWidget);
    expect(find.text('Image 7'), findsOneWidget);
    expect(find.text('Text 5'), findsOneWidget);
  });
}
