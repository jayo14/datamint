import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datamint_mobile/app/theme/app_theme.dart';
import 'package:datamint_mobile/features/auth/auth_screens.dart';

void main() {
  testWidgets('AuthWelcomeScreen renders titles and action buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthWelcomeScreen(),
        ),
      ),
    );

    expect(find.text('Earn while you teach AI.'), findsOneWidget);
    expect(find.text('Continue with MiniPay'), findsOneWidget);
    expect(find.text('Connect another wallet'), findsOneWidget);
    expect(find.text('Use phone or email'), findsOneWidget);
  });

  testWidgets('AuthPhoneScreen switches between Phone and Email', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthPhoneScreen(),
        ),
      ),
    );

    expect(find.text('What’s your phone number?'), findsOneWidget);
    await tester.tap(find.text('Email'));
    await tester.pump();
    expect(find.text('What’s your email address?'), findsOneWidget);
  });

  testWidgets('AuthProfileScreen renders profile inputs and chips', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthProfileScreen(),
        ),
      ),
    );

    expect(find.text('Tell us how you speak'), findsOneWidget);
    expect(find.text('Nigeria'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Yoruba'), findsOneWidget);
  });

  testWidgets('AuthSuccessScreen renders congratulations and first task offer', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthSuccessScreen(),
        ),
      ),
    );

    expect(find.text('You’re in, Amina.'), findsOneWidget);
    expect(find.text('Say a short phrase'), findsOneWidget);
    expect(find.text('Try my first task'), findsOneWidget);
  });
}
