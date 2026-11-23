import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datamint_mobile/features/wallet/wallet_screen.dart';
import 'package:datamint_mobile/features/wallet/history_screen.dart';
import 'package:datamint_mobile/features/wallet/receipt_screen.dart';

void main() {
  testWidgets('WalletScreen renders balance and cash out button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WalletScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Cash out'), findsOneWidget);
  });

  testWidgets('HistoryScreen renders month sum and transactions', (tester) async {

    await tester.pumpWidget(
      const MaterialApp(
        home: HistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('+18.40 cUSD'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
  });

  testWidgets('ReceiptScreen renders receipt details', (tester) async {

    await tester.pumpWidget(
      const MaterialApp(
        home: ReceiptScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Receipt'), findsOneWidget);
    expect(find.text('+0.50 cUSD'), findsOneWidget);
    expect(find.text('PAID'), findsOneWidget);
    expect(find.text('View on Celo explorer'), findsOneWidget);
  });
}
