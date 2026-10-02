import 'package:flutter_test/flutter_test.dart';
import 'package:gemeye/services/calibration_service.dart';

void main() {
  final reference = kCalibrationPatches
      .map((p) => p.rgb.map((v) => v.toDouble()).toList())
      .toList();

  test('computeCcm identity: measured == reference gives residual 0', () {
    final result = CalibrationService.computeCcm(reference, reference);
    const identity = [1.0, 0, 0, 0, 1, 0, 0, 0, 1];
    for (var i = 0; i < 9; i++) {
      expect(result.ccm[i], closeTo(identity[i], 1e-9));
    }
    expect(result.residual, closeTo(0, 1e-9));
    for (final e in result.perPatchError) {
      expect(e, closeTo(0, 1e-9));
    }
    expect(result.quality, CalibrationQuality.excellent);
  });

  test('computeCcm recovers a uniform channel gain', () {
    final measured =
        reference.map((p) => p.map((v) => v * 0.8).toList()).toList();
    final result = CalibrationService.computeCcm(measured, reference);
    expect(result.ccm[0], closeTo(1.25, 1e-9));
    expect(result.ccm[4], closeTo(1.25, 1e-9));
    expect(result.ccm[8], closeTo(1.25, 1e-9));
    expect(result.residual, closeTo(0, 1e-9));
    expect(CalibrationService.applyCcm(result.ccm, 80, 80, 80),
        [100, 100, 100]);
  });

  test('quality thresholds', () {
    expect(qualityForResidual(0.2548), CalibrationQuality.excellent);
    expect(qualityForResidual(0.40), CalibrationQuality.acceptable);
    expect(qualityForResidual(0.50), CalibrationQuality.poor);
  });
}
