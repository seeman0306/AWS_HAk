import 'package:flutter_test/flutter_test.dart';
import 'package:civiceye_ai/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CivicEyeApp());
    expect(find.text('CivicEye '), findsOneWidget);
  });
}
