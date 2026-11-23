import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datamint_mobile/features/task_flow/voice_screens.dart';
import 'package:datamint_mobile/features/task_flow/validation_screens.dart';

void main() {
  testWidgets('VoiceReadyScreen renders prompt and action button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: VoiceReadyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Say this phrase out loud'), findsOneWidget);
    expect(find.text('Tap to start recording'), findsOneWidget);
  });

  testWidgets('TaskPaidScreen renders payout confirmation and amount', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TaskPaidScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Task approved'), findsOneWidget);
    expect(find.text('+0.50'), findsOneWidget);
    expect(find.text('cUSD paid to your wallet'), findsOneWidget);
  });
}
