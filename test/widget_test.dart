import 'package:flutter_test/flutter_test.dart';
import 'package:fixnow/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const FixNowApp());
  });
}
