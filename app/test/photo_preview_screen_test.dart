import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemeye/screens/photo_preview_screen.dart';

void main() {
  testWidgets('each button calls its handler', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: PhotoPreviewScreen(
        imagePath: 'missing.jpg',
        onUse: (_) => taps.add('use'),
        onCrop: (_) => taps.add('crop'),
        onRetake: (_) => taps.add('retake'),
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('Use photo'));
    await tester.tap(find.text('Crop (optional)'));
    await tester.ensureVisible(find.text('Retake'));
    await tester.tap(find.text('Retake'));
    expect(taps, ['use', 'crop', 'retake']);
  });

  testWidgets('no overflow at 360 dp with large text', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
            size: Size(360, 740), textScaler: TextScaler.linear(1.6)),
        child: PhotoPreviewScreen(
          imagePath: 'missing.jpg',
          onUse: (_) {},
          onCrop: (_) {},
          onRetake: (_) {},
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
