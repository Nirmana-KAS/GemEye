import 'package:flutter_test/flutter_test.dart';
import 'package:gemeye/models/grade_result.dart';
import 'package:gemeye/models/grading_response.dart';

Map<String, dynamic> okJson() => {
      'status': 'ok',
      'warnings': ['unusual_image'],
      'grade': 6,
      'grade_name': 'Light',
      'trade_name': 'Pastel Blue',
      'probabilities': [0.0, 0.01, 0.02, 0.05, 0.12, 0.7, 0.1],
      'confidence': 0.7,
      'uncertainty': 0.35,
      'referred': false,
      'second_grade': 5,
      'colour': <String, dynamic>{
        'L': 55.1,
        'a': 2.3,
        'b': -30.4,
        'C': 30.5,
        'H': 221.0,
        'S': 48.0,
        'B': 71.0,
        'hex': '#6F8BC0',
        'ciecam02': {'J': 50.2, 'M': 28.1, 'h': 250.3, 's': 40.4, 'C': 31.2},
        'approximate': false,
      },
      'delta_e00_to_typical': 1.8,
      'calibration_mode': 'training_session',
      'model_version': 'v3',
      'timings_ms': {'total': 900.0, 'preprocess': 100.0, 'rf': 5.0, 'cnn': 700.0},
      'diagnostics': {'blur_variance': 120.5},
      'grading_id': 'abc123',
      'stone_id': 'GE-STONE-00042',
      'image_url': 'https://example.com/x.jpg',
    };

void main() {
  test('ok response maps to GradeResult', () {
    final r = GradingResponse.fromJson(okJson(),
        capturedImagePath: '/tmp/s.jpg', sessionId: 'S-2026-10-05-01');
    expect(r.isOk, isTrue);
    expect(r.status, GradingStatus.ok);
    expect(r.warnings, ['unusual_image']);
    final g = r.result!;
    expect(g.id, 'abc123');
    expect(g.gradingId, 'abc123');
    expect(g.stoneId, 'GE-STONE-00042');
    expect(g.gradeNumber, 6);
    expect(g.gradeName, 'Light');
    expect(g.tradeName, 'Pastel Blue');
    expect(g.confidence, closeTo(70, 1e-9));
    expect(g.uncertaintyRange, 0.35);
    expect(g.uncertainty, 0.35);
    expect(g.probabilities, hasLength(7));
    expect(g.probabilities![5], closeTo(70, 1e-9));
    expect(g.secondGrade, 5);
    expect(g.referred, isFalse);
    expect(g.labL, 55.1);
    expect(g.labC, 30.5);
    expect(g.hue, 221.0);
    expect(g.saturation, 48.0);
    expect(g.brightness, 71.0);
    expect(g.deltaE, 1.8);
    expect(g.colourHex, '#6F8BC0');
    expect(g.colourApproximate, isFalse);
    expect(g.ciecam02!.j, 50.2);
    expect(g.ciecam02!.c, 31.2);
    expect(g.modelVersion, 'v3');
    expect(g.calibrationMode, 'training_session');
    expect(g.imageUrl, 'https://example.com/x.jpg');
    expect(g.capturedImagePath, '/tmp/s.jpg');
    expect(g.sessionId, 'S-2026-10-05-01');
  });

  test('ok response without CIECAM02 and with approximate colour', () {
    final json = okJson();
    (json['colour'] as Map<String, dynamic>)
      ..['ciecam02'] = null
      ..['approximate'] = true;
    final g = GradingResponse.fromJson(json, capturedImagePath: 'p').result!;
    expect(g.ciecam02, isNull);
    expect(g.colourApproximate, isTrue);
  });

  test('GradeResult JSON round trip keeps the server fields', () {
    final g = GradingResponse.fromJson(okJson(), capturedImagePath: 'p').result!;
    final back = GradeResult.fromJson(g.toJson());
    expect(back.toJson(), g.toJson());
  });

  test('history saved before the API still loads', () {
    final legacy = {
      'id': 'x', 'stoneId': 'GE-STONE-00001', 'gradeNumber': 3,
      'gradeName': 'Vivid', 'tradeName': 'Royal Blue', 'confidence': 92.4,
      'uncertaintyRange': 0.2, 'labL': 42.3, 'labA': 8.9, 'labB': -27.0,
      'labC': 28.4, 'hue': 228, 'saturation': 88, 'brightness': 62,
      'deltaE': 1.2, 'capturedImagePath': 'p', 'gradcamImagePath': null,
      'certificateNumber': null, 'capturedAt': '2026-09-01T10:00:00.000',
      'sessionId': 'S-2026-09-01-01',
    };
    final g = GradeResult.fromJson(legacy);
    expect(g.gradingId, isNull);
    expect(g.probabilities, isNull);
    expect(g.warnings, isEmpty);
  });

  const rejections = {
    'invalid_image': GradingStatus.invalidImage,
    'blurry': GradingStatus.blurry,
    'no_stone': GradingStatus.noStone,
    'not_blue': GradingStatus.notBlue,
    'not_recognised': GradingStatus.notRecognised,
  };
  for (final e in rejections.entries) {
    test('rejection ${e.key}', () {
      final r = GradingResponse.fromJson({
        'status': e.key,
        'message': 'Server message for ${e.key}.',
        'diagnostics': {'short_side_px': 1200, 'hue_wb': 140.5},
      }, capturedImagePath: 'p');
      expect(r.status, e.value);
      expect(r.rawStatus, e.key);
      expect(r.isOk, isFalse);
      expect(r.result, isNull);
      expect(r.message, 'Server message for ${e.key}.');
      expect(r.diagnostics['short_side_px'], 1200);
      expect(r.measuredHue, 140.5);
    });
  }

  test('unknown status is not ok', () {
    final r = GradingResponse.fromJson(
        {'status': 'something_new', 'diagnostics': {}},
        capturedImagePath: 'p');
    expect(r.status, GradingStatus.unknown);
    expect(r.rawStatus, 'something_new');
    expect(r.isOk, isFalse);
  });
}
