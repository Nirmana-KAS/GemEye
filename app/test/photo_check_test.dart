import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:gemeye/services/photo_check_service.dart';
import 'package:gemeye/services/remote_config_service.dart';

/// Reference values printed by the server for the same PNG files:
///   docker compose exec api python scripts/blur_variance.py <files>
/// (backend/app/pipeline/inference.py blur_variance, OpenCV 4.14).
const Map<String, double> kServerBlurVariance = {
  'area_1600x1200_sharp.png': 1116.1474029583235,
  'fast2x_1024x768_blur.png': 5.992231044504378,
  'fast4x_2048x1536_sharp.png': 1431.3906834506324,
  'portrait_700x1050_blur.png': 342.0508178795415,
  'upscale_400x300_sharp.png': 528.5727320098215,
};

void main() {
  for (final e in kServerBlurVariance.entries) {
    test('blur variance equals the server: ${e.key}', () {
      final image =
          img.decodePng(File('test/fixtures/blur/${e.key}').readAsBytesSync())!;
      final rgb = image
          .convert(format: img.Format.uint8, numChannels: 3)
          .getBytes(order: img.ChannelOrder.rgb);
      final v = blurVariance(rgb, image.width, image.height);
      expect(v, closeTo(e.value, e.value * 1e-9));
    });
  }

  test('sharp / blurry against the server threshold', () {
    const t = kDefaultBlurMinVariance;
    PhotoCheckResult r(double v) =>
        PhotoCheckResult(blurVariance: v, stoneShare: 0.3, blurThreshold: t);
    expect(r(kServerBlurVariance['fast2x_1024x768_blur.png']!).isSharp, isFalse);
    expect(r(kServerBlurVariance['portrait_700x1050_blur.png']!).isSharp, isTrue);
    expect(r(t).isSharp, isTrue);
  });

  test('remote config overrides the threshold', () {
    RemoteConfigService.apply({
      'blur_min_variance': 40.5,
      'features': {'gradcam': true, 'session_mapping': false},
      'maintenance': {'enabled': false, 'message': ''},
    });
    expect(RemoteConfigService.blurMinVariance, 40.5);
    expect(RemoteConfigService.gradcamEnabled, isTrue);
    RemoteConfigService.apply({});
    expect(RemoteConfigService.blurMinVariance, kDefaultBlurMinVariance);
    expect(RemoteConfigService.gradcamEnabled, isFalse);
  });
}
