import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemeye/utils/stone_autocrop.dart';
import 'package:image/image.dart' as img;

/// Light grey tray with an optional blue disc, encoded as JPEG.
Uint8List _tray(int w, int h, {int? cx, int? cy, int r = 0}) {
  final im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(220, 222, 224));
  if (cx != null && cy != null && r > 0) {
    img.fillCircle(im,
        x: cx, y: cy, radius: r, color: img.ColorRgb8(40, 60, 160));
  }
  return Uint8List.fromList(img.encodeJpg(im, quality: 95));
}

void _expectSquareAtTarget(AutoCropResult r) {
  expect(r.status, AutoCropStatus.ok);
  final out = img.decodeJpg(r.croppedJpeg!)!;
  expect(out.width, out.height);
  expect(out.width, r.cropSide);
  expect(r.stoneWidthRatio!, closeTo(kTargetStoneRatio, 0.02));
  // The stone measured again in the crop sits at the target ratio.
  expect(measureStoneRatio(r.croppedJpeg!)!, closeTo(kTargetStoneRatio, 0.02));
}

void main() {
  test('centred disc: square crop at the target ratio', () {
    final r = autoCropStone(_tray(1200, 1200, cx: 600, cy: 600, r: 120));
    _expectSquareAtTarget(r);
    expect(r.stoneBox!.diameter, closeTo(240, 6));
  });

  test('off-centre disc near an edge: crop shifted inside the image', () {
    final r = autoCropStone(_tray(1600, 1200, cx: 260, cy: 600, r: 100));
    _expectSquareAtTarget(r);
  });

  test('small disc in a large photo: ok', () {
    final r = autoCropStone(_tray(2000, 2000, cx: 1000, cy: 1000, r: 60));
    _expectSquareAtTarget(r);
  });

  test('very large disc: tooClose', () {
    final r = autoCropStone(_tray(1200, 1200, cx: 600, cy: 600, r: 400));
    expect(r.status, AutoCropStatus.tooClose);
    expect(r.stoneWidthRatio!, greaterThan(kMaxStoneRatio));
  });

  test('no disc: notFound', () {
    final r = autoCropStone(_tray(1200, 1200));
    expect(r.status, AutoCropStatus.notFound);
    expect(r.croppedJpeg, isNull);
  });

  test('tiny image: tooSmallImage', () {
    final r = autoCropStone(_tray(300, 300, cx: 150, cy: 150, r: 30));
    expect(r.status, AutoCropStatus.tooSmallImage);
    expect(r.croppedJpeg, isNull);
  });

  test('unreadable bytes: notFound', () {
    final r = autoCropStone(Uint8List.fromList([1, 2, 3]));
    expect(r.status, AutoCropStatus.notFound);
  });

  test('ratio limits are ordered around the target', () {
    expect(kMinStoneRatio, lessThan(kTargetStoneRatio));
    expect(kTargetStoneRatio, lessThan(kMaxStoneRatio));
  });
}
