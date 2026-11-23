import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datamint_mobile/features/settings/settings_screen.dart';
import 'package:datamint_mobile/features/notifications/notifications_screen.dart';
import 'package:datamint_mobile/features/offline/offline_screen.dart';

void main() {
  testWidgets('SettingsScreen renders account, notifications, and privacy options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    await tester.drag(find.text('Privacy'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('NotificationsScreen renders notifications list and mark all read', (tester) async {

    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
    expect(find.text('+0.50 cUSD received'), findsOneWidget);
  });

  testWidgets('OfflineScreen renders offline message and cached queue', (tester) async {

    await tester.pumpWidget(
      const MaterialApp(
        home: OfflineScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You’re offline'), findsOneWidget);
    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('1 recording waiting'), findsOneWidget);
  });
}
