import 'package:flutter_test/flutter_test.dart';
import 'package:gemeye/main.dart';

void main() {
  testWidgets('GemEye app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const GemEyeApp());
  });
}
