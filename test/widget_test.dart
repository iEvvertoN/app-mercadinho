import 'package:flutter_test/flutter_test.dart';
import 'package:app_mercadinho/main.dart';

void main() {
  testWidgets('AppMercadinho smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AppMercadinho());
    expect(find.text('APP DO MERCADINHO'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
