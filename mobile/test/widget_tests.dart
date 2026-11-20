import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datamint_mobile/core/constants/app_constants.dart';
import 'package:datamint_mobile/core/widgets/common_widgets.dart';
import 'package:datamint_mobile/features/authentication/login_screen.dart';
import 'package:datamint_mobile/features/authentication/register_screen.dart';
import 'package:datamint_mobile/features/onboarding/onboarding_screen.dart';
import 'package:datamint_mobile/features/splash/splash_screen.dart';
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

  group('SplashScreen Branding & UI', () {
    testWidgets('renders brand elements and logo emblem', (tester) async {
      final mockStorage = MockStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      expect(find.text('DataMint'), findsOneWidget);
      expect(find.text('Decentralized AI Dataset Marketplace'), findsOneWidget);
      expect(find.text('Celo L2 • Audited Smart Escrow'), findsOneWidget);
      expect(find.text('⌘'), findsOneWidget);
    });
  });

  group('OnboardingScreen Carousel & UI', () {
    testWidgets('renders carousel cards and navigation buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      expect(find.text('DataMint'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Decentralized AI Dataset Marketplace'), findsOneWidget);
      expect(find.text('Audited Smart Escrow'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });

  group('RegisterScreen Form & Role Capabilities', () {
    testWidgets('renders register fields and validates input', (tester) async {
      final mockStorage = MockStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      expect(find.text('Join DataMint'), findsOneWidget);
      expect(find.text('Decentralized Protocol'), findsOneWidget);
      expect(find.text('Dual Role (Recommended)'), findsOneWidget);
      expect(find.text('Create Account'), findsWidgets);

      final buttonFinder = find.byType(ElevatedButton).first;
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });
}
