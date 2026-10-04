import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../services/settings_service.dart';

/// CIECAM02 appearance values from the server (display path).
class Ciecam02 {
  final double j;
  final double m;
  final double h;
  final double s;
  final double c;

  const Ciecam02({
    required this.j,
    required this.m,
    required this.h,
    required this.s,
    required this.c,
  });

  Map<String, dynamic> toJson() => {'J': j, 'M': m, 'h': h, 's': s, 'C': c};

  factory Ciecam02.fromJson(Map<String, dynamic> json) => Ciecam02(
        j: (json['J'] as num).toDouble(),
        m: (json['M'] as num).toDouble(),
        h: (json['h'] as num).toDouble(),
        s: (json['s'] as num).toDouble(),
        c: (json['C'] as num).toDouble(),
      );
}

class GradeResult {
  final String id;
  final String stoneId;
  final int gradeNumber;
  final String gradeName;
  final String tradeName;

  /// Ensemble confidence in percent (0-100).
  final double confidence;

  /// Model uncertainty in grades (the server's `uncertainty`).
  final double uncertaintyRange;
  final double labL;
  final double labA;
  final double labB;
  final double labC;

  /// Hue in degrees; saturation and brightness in percent.
  final double hue;
  final double saturation;
  final double brightness;

  /// ΔE₀₀ to the typical colour of the grade (`delta_e00_to_typical`).
  final double deltaE;
  final String capturedImagePath;
  final String? gradcamImagePath;
  String? certificateNumber;

  /// Public verification URL of the server certificate. Null for a number
  /// issued before certificates came from the server (offline certificate).
  String? certificateVerifyUrl;
  final DateTime capturedAt;
  final String sessionId;

  // Server fields (null for results saved before the API was connected).

  /// Server grading id (`grading_id`).
  final String? gradingId;

  /// Presigned image URL (valid 10 minutes).
  final String? imageUrl;

  /// Per-grade probabilities in percent, G1-G7.
  final List<double>? probabilities;
  final int? secondGrade;

  /// Borderline at grading time, against the threshold used then.
  final bool? referred;
  final List<String> warnings;
  final Ciecam02? ciecam02;

  /// True when the colour values are approximate (`colour.approximate`).
  final bool colourApproximate;

  /// Measured colour hex from the server (`colour.hex`).
  final String? colourHex;
  final String? modelVersion;
  final String? calibrationMode;

  GradeResult({
    String? id,
    required this.stoneId,
    required this.gradeNumber,
    required this.gradeName,
    required this.tradeName,
    required this.confidence,
    required this.uncertaintyRange,
    required this.labL,
    required this.labA,
    required this.labB,
    required this.labC,
    required this.hue,
    required this.saturation,
    required this.brightness,
    required this.deltaE,
    required this.capturedImagePath,
    this.gradcamImagePath,
    this.certificateNumber,
    this.certificateVerifyUrl,
    DateTime? capturedAt,
    String? sessionId,
    this.gradingId,
    this.imageUrl,
    this.probabilities,
    this.secondGrade,
    this.referred,
    this.warnings = const [],
    this.ciecam02,
    this.colourApproximate = false,
    this.colourHex,
    this.modelVersion,
    this.calibrationMode,
  })  : id = id ?? const Uuid().v4(),
        capturedAt = capturedAt ?? DateTime.now(),
        sessionId = sessionId ?? 'SESSION-${DateTime.now().millisecondsSinceEpoch}';

  /// Builds a result from a `/grade` (or `/gradings`) response with
  /// `status: "ok"`. Confidence and probabilities become percentages.
  factory GradeResult.fromApi(
    Map<String, dynamic> json, {
    required String capturedImagePath,
    String? sessionId,
    DateTime? capturedAt,
  }) {
    final colour = json['colour'] as Map<String, dynamic>;
    double num0(Object? v) => v == null ? 0 : (v as num).toDouble();
    final gradingId = json['grading_id'] as String?;
    return GradeResult(
      id: gradingId,
      stoneId: json['stone_id'] as String? ?? '',
      gradeNumber: json['grade'] as int,
      gradeName: json['grade_name'] as String,
      tradeName: json['trade_name'] as String,
      confidence: num0(json['confidence']) * 100,
      uncertaintyRange: num0(json['uncertainty']),
      labL: num0(colour['L']),
      labA: num0(colour['a']),
      labB: num0(colour['b']),
      labC: num0(colour['C']),
      hue: num0(colour['H']),
      saturation: num0(colour['S']),
      brightness: num0(colour['B']),
      deltaE: num0(json['delta_e00_to_typical']),
      capturedImagePath: capturedImagePath,
      capturedAt: capturedAt,
      sessionId: sessionId ?? '',
      gradingId: gradingId,
      imageUrl: json['image_url'] as String?,
      probabilities: (json['probabilities'] as List?)
          ?.map((p) => (p as num).toDouble() * 100)
          .toList(),
      secondGrade: json['second_grade'] as int?,
      referred: json['referred'] as bool?,
      warnings: (json['warnings'] as List?)?.cast<String>() ?? const [],
      ciecam02: colour['ciecam02'] == null
          ? null
          : Ciecam02.fromJson(colour['ciecam02'] as Map<String, dynamic>),
      colourApproximate: colour['approximate'] as bool? ?? false,
      colourHex: colour['hex'] as String?,
      modelVersion: json['model_version'] as String?,
      calibrationMode: json['calibration_mode'] as String?,
    );
  }

  /// Builds a result from a `GET /gradings` item: the stored `/grade`
  /// response in `result` plus the item's ids, photo URL and session.
  factory GradeResult.fromGradingItem(
    Map<String, dynamic> item, {
    String capturedImagePath = '',
  }) {
    final result = (item['result'] as Map).cast<String, dynamic>();
    return GradeResult.fromApi(
      {
        ...result,
        'grading_id': item['grading_id'],
        'stone_id': item['stone_id'],
        'image_url': item['image_url'],
      },
      capturedImagePath: capturedImagePath,
      sessionId: item['calibration_session_id'] as String?,
      capturedAt: DateTime.parse(item['created_at'] as String).toLocal(),
    );
  }

  /// Borderline: the server's flag from grading time, or (for results
  /// without one) the confidence against the current referral threshold.
  bool get isReferred =>
      referred ?? SettingsService.isReferred(confidence);

  /// Same as [uncertaintyRange] (grades).
  double get uncertainty => uncertaintyRange;

  Map<String, dynamic> toJson() => {
        'id': id,
        'stoneId': stoneId,
        'gradeNumber': gradeNumber,
        'gradeName': gradeName,
        'tradeName': tradeName,
        'confidence': confidence,
        'uncertaintyRange': uncertaintyRange,
        'labL': labL,
        'labA': labA,
        'labB': labB,
        'labC': labC,
        'hue': hue,
        'saturation': saturation,
        'brightness': brightness,
        'deltaE': deltaE,
        'capturedImagePath': capturedImagePath,
        'gradcamImagePath': gradcamImagePath,
        'certificateNumber': certificateNumber,
        'certificateVerifyUrl': certificateVerifyUrl,
        'capturedAt': capturedAt.toIso8601String(),
        'sessionId': sessionId,
        'gradingId': gradingId,
        'imageUrl': imageUrl,
        'probabilities': probabilities,
        'secondGrade': secondGrade,
        'referred': referred,
        'warnings': warnings,
        'ciecam02': ciecam02?.toJson(),
        'colourApproximate': colourApproximate,
        'colourHex': colourHex,
        'modelVersion': modelVersion,
        'calibrationMode': calibrationMode,
      };

  factory GradeResult.fromJson(Map<String, dynamic> json) => GradeResult(
        id: json['id'] as String,
        stoneId: json['stoneId'] as String,
        gradeNumber: json['gradeNumber'] as int,
        gradeName: json['gradeName'] as String,
        tradeName: json['tradeName'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        uncertaintyRange: (json['uncertaintyRange'] as num).toDouble(),
        labL: (json['labL'] as num).toDouble(),
        labA: (json['labA'] as num).toDouble(),
        labB: (json['labB'] as num).toDouble(),
        labC: (json['labC'] as num).toDouble(),
        hue: (json['hue'] as num).toDouble(),
        saturation: (json['saturation'] as num).toDouble(),
        brightness: (json['brightness'] as num).toDouble(),
        deltaE: (json['deltaE'] as num).toDouble(),
        capturedImagePath: json['capturedImagePath'] as String,
        gradcamImagePath: json['gradcamImagePath'] as String?,
        certificateNumber: json['certificateNumber'] as String?,
        certificateVerifyUrl: json['certificateVerifyUrl'] as String?,
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        sessionId: json['sessionId'] as String,
        gradingId: json['gradingId'] as String?,
        imageUrl: json['imageUrl'] as String?,
        probabilities: (json['probabilities'] as List?)
            ?.map((p) => (p as num).toDouble())
            .toList(),
        secondGrade: json['secondGrade'] as int?,
        referred: json['referred'] as bool?,
        warnings: (json['warnings'] as List?)?.cast<String>() ?? const [],
        ciecam02: json['ciecam02'] == null
            ? null
            : Ciecam02.fromJson(json['ciecam02'] as Map<String, dynamic>),
        colourApproximate: json['colourApproximate'] as bool? ?? false,
        colourHex: json['colourHex'] as String?,
        modelVersion: json['modelVersion'] as String?,
        calibrationMode: json['calibrationMode'] as String?,
      );

  /// Copy with a new stone ID (all other values unchanged).
  GradeResult withStoneId(String newStoneId) => GradeResult(
        id: id,
        stoneId: newStoneId,
        gradeNumber: gradeNumber,
        gradeName: gradeName,
        tradeName: tradeName,
        confidence: confidence,
        uncertaintyRange: uncertaintyRange,
        labL: labL,
        labA: labA,
        labB: labB,
        labC: labC,
        hue: hue,
        saturation: saturation,
        brightness: brightness,
        deltaE: deltaE,
        capturedImagePath: capturedImagePath,
        gradcamImagePath: gradcamImagePath,
        certificateNumber: certificateNumber,
        certificateVerifyUrl: certificateVerifyUrl,
        capturedAt: capturedAt,
        sessionId: sessionId,
        gradingId: gradingId,
        imageUrl: imageUrl,
        probabilities: probabilities,
        secondGrade: secondGrade,
        referred: referred,
        warnings: warnings,
        ciecam02: ciecam02,
        colourApproximate: colourApproximate,
        colourHex: colourHex,
        modelVersion: modelVersion,
        calibrationMode: calibrationMode,
      );

  /// Measured colour as sRGB [r, g, b] (0-255), from CIELAB (D65).
  List<int> get measuredRgb {
    final fy = (labL + 16) / 116;
    final fx = fy + labA / 500;
    final fz = fy - labB / 200;
    double inv(double t) => t * t * t > 0.008856 ? t * t * t : (t - 16 / 116) / 7.787;
    final x = 0.95047 * inv(fx);
    final y = 1.0 * inv(fy);
    final z = 1.08883 * inv(fz);
    final lin = [
      3.2406 * x - 1.5372 * y - 0.4986 * z,
      -0.9689 * x + 1.8758 * y + 0.0415 * z,
      0.0557 * x - 0.2040 * y + 1.0570 * z,
    ];
    return lin.map((c) {
      final v = c <= 0.0031308 ? 12.92 * c : 1.055 * math.pow(c, 1 / 2.4) - 0.055;
      return (v * 255).round().clamp(0, 255);
    }).toList();
  }

  /// Measured colour as "#RRGGBB".
  String get measuredHex =>
      '#${measuredRgb.map((v) => v.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';

  String get confidenceLevel {
    if (confidence >= 80) return 'HIGH';
    if (confidence >= 50) return 'MEDIUM';
    return 'LOW';
  }

  String get gradeColourHex {
    const colours = {
      1: '#091A47',
      2: '#102670',
      3: '#1B3A8C',
      4: '#2E5BB8',
      5: '#4A80D4',
      6: '#7BA7E8',
      7: '#A8C8F0',
    };
    return colours[gradeNumber] ?? '#1B3A8C';
  }
}
