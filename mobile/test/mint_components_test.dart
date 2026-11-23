import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:datamint_mobile/app/theme/app_theme.dart';
import 'package:datamint_mobile/core/widgets/mint_components.dart';

void main() {
  testWidgets('MintDCoin renders correctly with given size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MintDCoin(size: 100),
        ),
      ),
    );

    expect(find.text('D'), findsOneWidget);
    expect(find.byType(MintDCoin), findsOneWidget);
  });

  testWidgets('MintButton renders primary and dark variants and handles tap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MintButton(
            label: 'Test Button',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);
    await tester.tap(find.text('Test Button'));
    expect(tapped, isTrue);
  });

  testWidgets('MintTypePill renders all modality and status types', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MintTypePill(type: MintPillType.voice),
              MintTypePill(type: MintPillType.image),
              MintTypePill(type: MintPillType.text),
              MintTypePill(type: MintPillType.paid),
              MintTypePill(type: MintPillType.review),
            ],
          ),
        ),
      ),
    );

    expect(find.text('VOICE'), findsOneWidget);
    expect(find.text('IMAGE'), findsOneWidget);
    expect(find.text('TEXT'), findsOneWidget);
    expect(find.text('PAID'), findsOneWidget);
    expect(find.text('REVIEW'), findsOneWidget);
  });

  testWidgets('MintSegmentedControl switches selection on tap', (tester) async {
    int selected = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: MintSegmentedControl(
                options: const ['Phone', 'Email'],
                selectedIndex: selected,
                onSelected: (i) => setState(() => selected = i),
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    await tester.tap(find.text('Email'));
    await tester.pump();
    expect(selected, equals(1));
  });

  testWidgets('MintOtpBoxes renders digits and empty boxes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MintOtpBoxes(
            length: 6,
            value: '123',
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('MintNumericKeypad triggers callbacks on tap', (tester) async {
    String pressed = '';
    bool backspaceCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MintNumericKeypad(
            onKeyPress: (k) => pressed += k,
            onBackspace: () => backspaceCalled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('5'));
    await tester.tap(find.text('8'));
    expect(pressed, equals('58'));

    await tester.tap(find.byIcon(Symbols.backspace));
    expect(backspaceCalled, isTrue);
  });
}
