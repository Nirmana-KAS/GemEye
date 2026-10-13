import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemeye/utils/photo_check_math.dart';
import 'package:gemeye/utils/upload_jpeg.dart';
import 'package:image/image.dart' as img;

/// Grey-white tray like the training images, optionally with a blue stone.
Uint8List _tray({bool stone = true, int w = 1200, int h = 1200}) {
  final im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(185, 195, 195));
  if (stone) {
    img.fillCircle(im,
        x: w ~/ 2, y: h ~/ 2, radius: w ~/ 7, color: img.ColorRgb8(40, 60, 160));
  }
  return Uint8List.fromList(img.encodeJpg(im, quality: 95));
}

Uint8List _jpeg(int w, int h, {int? orientation}) {
  final im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(200, 205, 210));
  if (orientation != null) im.exif.imageIfd.orientation = orientation;
  return Uint8List.fromList(img.encodeJpg(im, quality: 95));
}

void main() {
  group('framing check', () {
    test('grey-white tray with a blue stone: stone found', () {
      expect(measurePhotoCheck(_tray()).stoneFound, isTrue);
    });

    test('empty grey-white tray: stone not found', () {
      expect(measurePhotoCheck(_tray(stone: false)).stoneFound, isFalse);
    });
  });

  group('untouched upload', () {
    test('small upright JPEG is sent byte-identical', () {
      final b = _jpeg(1228, 1228);
      expect(canUploadUnchanged(b), isTrue);
      expect(prepareUploadJpeg(b), same(b));
    });

    test('orientation 1 is sent unchanged', () {
      final b = _jpeg(800, 600, orientation: 1);
      expect(prepareUploadJpeg(b), same(b));
    });

    test('larger than 2048 px is re-encoded and downscaled', () {
      final b = _jpeg(2600, 1300);
      final out = prepareUploadJpeg(b);
      expect(out, isNot(equals(b)));
      final d = img.decodeJpg(out)!;
      expect(d.width, kUploadMaxSide);
    });

    test('rotated JPEG is re-encoded upright', () {
      final b = _jpeg(800, 600, orientation: 6);
      expect(img.decodeJpgExif(b)!.imageIfd.orientation, 6);
      final out = prepareUploadJpeg(b);
      expect(out, isNot(equals(b)));
      final d = img.decodeJpg(out)!;
      expect([d.width, d.height], [600, 800]);
    });

    test('PNG is re-encoded as JPEG', () {
      final png = Uint8List.fromList(
          img.encodePng(img.Image(width: 400, height: 300)));
      final out = prepareUploadJpeg(png);
      expect(out.sublist(0, 2), [0xFF, 0xD8]);
    });
  });
}
