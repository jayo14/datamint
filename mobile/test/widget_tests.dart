import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datamint_mobile/core/constants/app_constants.dart';
import 'package:datamint_mobile/core/widgets/common_widgets.dart';
import 'package:datamint_mobile/features/authentication/login_screen.dart';
import 'package:datamint_mobile/shared/providers/app_providers.dart';
import 'api_client_test.dart';

void main() {
  group('Common Core Widgets', () {
    testWidgets('DataMintButton renders label and triggers callback on tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataMintButton(
              label: 'Submit Verification',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit Verification'), findsOneWidget);
      await tester.tap(find.text('Submit Verification'));
      expect(tapped, isTrue);
    });

    testWidgets('DataMintButton displays CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataMintButton(
              label: 'Processing',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processing'), findsNothing);
    });

    testWidgets('StatusBadge displays correct text for APPROVED and REJECTED', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'APPROVED'),
                StatusBadge(status: 'REJECTED'),
                StatusBadge(status: 'HUMAN_REVIEW'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('APPROVED'), findsOneWidget);
      expect(find.text('REJECTED'), findsOneWidget);
      expect(find.text('HUMAN REVIEW'), findsOneWidget);
    });

    testWidgets('ModalityBadge renders icons and labels for TEXT, VOICE, IMAGE', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ModalityBadge(dataType: 'TEXT'),
                ModalityBadge(dataType: 'VOICE'),
                ModalityBadge(dataType: 'IMAGE'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('TEXT'), findsOneWidget);
      expect(find.text('VOICE'), findsOneWidget);
      expect(find.text('IMAGE'), findsOneWidget);
    });
  });

  group('WorkspaceNotifier Role Toggle', () {
    test('toggles seamlessly between Contributor and Creator', () async {
      final storage = MockStorageService();
      final notifier = WorkspaceNotifier(storage);

      expect(notifier.state, WorkspaceRole.contributor);

      notifier.toggle();
      expect(notifier.state, WorkspaceRole.creator);

      notifier.toggle();
      expect(notifier.state, WorkspaceRole.contributor);
    });
  });

  group('LoginScreen Form & Validation', () {
    testWidgets('validates required email and password fields on submit', (tester) async {
      final mockStorage = MockStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify screen elements
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Welcome to DataMint'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Scroll to button and tap Sign In
      final buttonFinder = find.byType(ElevatedButton).first;
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Form validation error should appear
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });
}
