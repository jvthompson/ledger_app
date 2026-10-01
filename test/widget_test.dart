import 'package:flutter_test/flutter_test.dart';

import 'package:ledger/app.dart';

void main() {
  testWidgets('LedgerApp launches to an empty grid at cell A1', (WidgetTester tester) async {
    await tester.pumpWidget(const LedgerApp());
    await tester.pumpAndSettle();

    expect(find.text('A1'), findsWidgets);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Sheet1'), findsOneWidget);
  });
}
