import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/main.dart';

void main() {
  testWidgets('WalletApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WalletApp());
    expect(find.text('Wallet & PDS Core'), findsOneWidget);
  });
}
