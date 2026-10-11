import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemeye/screens/calibration_screen.dart';
import 'package:gemeye/services/calibration_service.dart';

void main() {
  Future<void> pump(WidgetTester tester, {double scale = 1.0}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
            size: const Size(360, 800), textScaler: TextScaler.linear(scale)),
        child: const CalibrationScreen(),
      ),
    ));
  }

  testWidgets('shows 3 guidance lines and the 6-patch sequence',
      (tester) async {
    await pump(tester);
    expect(find.text('Same lighting you will grade in'), findsOneWidget);
    expect(find.text("Pro mode, white balance 'Daylight' locked"),
        findsOneWidget);
    expect(find.text('Same exposure for the patches and the stones'),
        findsOneWidget);
    expect(find.text('Calibration sequence'), findsOneWidget);
    for (final p in kCalibrationPatches) {
      expect(find.text(p.name), findsOneWidget);
      expect(find.text(rgbHex(p.rgb)), findsOneWidget);
    }
    expect(find.text('Phone on tripod'), findsNothing);
    expect(find.text('Macro lens + CPL attached'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow at 360 dp with large text', (tester) async {
    await pump(tester, scale: 1.6);
    expect(tester.takeException(), isNull);
  });
}
