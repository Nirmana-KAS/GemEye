import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemeye/services/calibration_service.dart';
import 'package:gemeye/services/remote_config_service.dart';

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

  test('relative quality limits X = 0.27, Y = 0.54', () {
    expect(qualityForResidual(0.27), CalibrationQuality.excellent);
    expect(qualityForResidual(0.2701), CalibrationQuality.acceptable);
    expect(qualityForResidual(0.54), CalibrationQuality.acceptable);
    expect(qualityForResidual(0.5401), CalibrationQuality.poor);
  });

  test('training patches fit themselves: relative residual ~0, excellent', () {
    final fit = relativeFit(kTrainingPatchRgb);
    expect(fit.residual, closeTo(0, 1e-9));
    expect(fit.quality, CalibrationQuality.excellent);
    for (final e in fit.perPatchError) {
      expect(e, closeTo(0, 1e-9));
    }
  });

  test('uniform gain of the training patches is excellent', () {
    final dimmer = kTrainingPatchRgb
        .map((p) => p.map((v) => v * 0.8).toList())
        .toList();
    final fit = relativeFit(dimmer);
    expect(fit.residual, closeTo(0, 1e-9));
    expect(fit.quality, CalibrationQuality.excellent);
  });

  group('sanity checks', () {
    test('white overexposed', () {
      expect(patchSanityFailure(0, [252, 251, 250]), kPatchMsgOverexposed);
      expect(patchSanityFailure(0, [255, 255, 249]), isNull);
      expect(patchSanityFailure(0, kTrainingPatchRgb[0]), isNull);
    });

    test('blue patch', () {
      expect(patchSanityFailure(4, kTrainingPatchRgb[4]), isNull);
      expect(patchSanityFailure(4, [100, 100, 115]), kPatchMsgNotBlue);
      expect(patchSanityFailure(4, [20, 160, 150]), kPatchMsgNotBlue);
    });

    test('red patch', () {
      expect(patchSanityFailure(5, kTrainingPatchRgb[5]), isNull);
      expect(patchSanityFailure(5, [140, 100, 130]), kPatchMsgNotRed);
      expect(patchSanityFailure(5, [150, 160, 40]), kPatchMsgNotRed);
    });

    test('other patches have no capture-time check', () {
      for (final i in [1, 2, 3]) {
        expect(patchSanityFailure(i, [255, 255, 255]), isNull);
      }
    });

    test('brightness order at finish', () {
      expect(patchOrderFailure(kTrainingPatchRgb), isNull);
      final swapped = [...kTrainingPatchRgb];
      swapped[2] = kTrainingPatchRgb[3];
      swapped[3] = kTrainingPatchRgb[2];
      expect(patchOrderFailure(swapped), kOrderMsgGreys);
      final blackTooBright = [...kTrainingPatchRgb];
      blackTooBright[1] = [130, 137, 142];
      expect(patchOrderFailure(blackTooBright), kOrderMsgGreys);
      final darkWhite = [...kTrainingPatchRgb];
      darkWhite[0] = [150, 160, 160];
      expect(patchOrderFailure(darkWhite), kOrderMsgWhite);
    });
  });

  group('trimmed uniformity', () {
    Uint8List pixels(int n, int Function(int i) value) {
      final out = Uint8List(n * 3);
      for (var i = 0; i < n; i++) {
        out.fillRange(i * 3, i * 3 + 3, value(i));
      }
      return out;
    }

    PatchMeasurement measure(Uint8List rgb) {
      final r = trimmedPatchStats(rgb);
      return PatchMeasurement(mean: r[0], std: r[1]);
    }

    test('ignores a 3% glare spot', () {
      final m = measure(pixels(10000, (i) => i < 300 ? 255 : 60));
      expect(m.mean[0], closeTo(60, 1e-9));
      expect(m.uniformity, PatchUniformity.pass);
    });

    test('fails a half shadow', () {
      final m = measure(pixels(10000, (i) => i < 5000 ? 180 : 60));
      expect(m.uniformity, PatchUniformity.fail);
    });

    test('moderate texture is a warning', () {
      // Alternating 100 / 160: std 30, between 0.10 and 0.15 x 255.
      final m = measure(pixels(10000, (i) => i.isEven ? 100 : 160));
      expect(m.uniformity, PatchUniformity.warning);
    });
  });

  test('old session JSON without relative fields still loads', () {
    final s = CalibrationSession.fromJson({
      'id': 'S-2026-10-05-01',
      'createdAt': '2026-10-05T09:35:00.000',
      'validUntil': '2026-10-05T17:35:00.000',
      'deviceModel': 'OnePlus DN2103',
      'ccm': [1.0, 0, 0, 0, 1, 0, 0, 0, 1],
      'residual': 0.1663,
      'quality': 'excellent',
      'measured': kTrainingPatchRgb,
      'perPatchError': List.filled(6, 0.1),
    });
    expect(s.relativeResidual, isNull);
    expect(s.relativePerPatchError, isNull);
    expect(s.residual, 0.1663);
    expect(s.toJson().containsKey('relativeResidual'), isFalse);
    expect(CalibrationService.serverBody(s).containsKey('relativeResidual'),
        isFalse);
  });

  CalibrationSession session(String id, DateTime validUntil) =>
      CalibrationSession(
        id: id,
        createdAt: validUntil.subtract(const Duration(hours: 24)),
        validUntil: validUntil,
        deviceModel: 'Test',
        ccm: const [1.0, 0, 0, 0, 1, 0, 0, 0, 1],
        residual: 0.1,
        quality: CalibrationQuality.excellent,
        measured: const [],
        perPatchError: const [],
      );

  group('validity from remote config', () {
    tearDown(() => RemoteConfigService.apply({}));

    test('defaults to 24 when missing or invalid', () {
      RemoteConfigService.apply({});
      expect(RemoteConfigService.calibrationValidityHours, 24);
      RemoteConfigService.apply({'calibration_validity_hours': 'x'});
      expect(RemoteConfigService.calibrationValidityHours, 24);
    });

    test('reads the server value and clamps to 1-72', () {
      RemoteConfigService.apply({'calibration_validity_hours': 12});
      expect(RemoteConfigService.calibrationValidityHours, 12);
      RemoteConfigService.apply({'calibration_validity_hours': 0});
      expect(RemoteConfigService.calibrationValidityHours, 1);
      RemoteConfigService.apply({'calibration_validity_hours': 500});
      expect(RemoteConfigService.calibrationValidityHours, 72);
    });
  });

  test('amber when 1 hour or less is left, red after expiry', () {
    final now = DateTime(2026, 10, 11, 12);
    CalibrationStatus at(Duration left) =>
        calibrationStatusAt(now.add(left), now);
    expect(calibrationStatusAt(null, now), CalibrationStatus.none);
    expect(at(const Duration(hours: 2)), CalibrationStatus.valid);
    expect(at(const Duration(minutes: 61)), CalibrationStatus.valid);
    expect(at(const Duration(hours: 1)), CalibrationStatus.expiringSoon);
    expect(at(const Duration(minutes: 5)), CalibrationStatus.expiringSoon);
    expect(at(Duration.zero), CalibrationStatus.expired);
    expect(at(const Duration(minutes: -1)), CalibrationStatus.expired);
  });

  test('remembered setup tick resets on a new session id or expiry', () {
    final live = session('S-1', DateTime.now().add(const Duration(hours: 5)));
    final next = session('S-2', DateTime.now().add(const Duration(hours: 5)));
    final dead = session('S-1', DateTime.now().subtract(const Duration(hours: 1)));
    expect(isSetupTickValid('S-1', live), isTrue);
    expect(isSetupTickValid('S-1', next), isFalse);
    expect(isSetupTickValid('S-1', dead), isFalse);
    expect(isSetupTickValid(null, live), isFalse);
    expect(isSetupTickValid('S-1', null), isFalse);
  });
}
