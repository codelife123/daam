// Smoke test: the app boots to the home screen.
import 'package:daam/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Daam app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const DaamApp());
    await tester.pumpAndSettle();
    expect(find.text('දාම්'), findsOneWidget);
  });
}
