import 'package:uuid/uuid.dart';

class GradeResult {
  final String id;
  final String stoneId;
  final int gradeNumber;
  final String gradeName;
  final String tradeName;
  final double confidence;
  final double uncertaintyRange;
  final double labL;
  final double labA;
  final double labB;
  final double labC;
  final double hue;
  final double saturation;
  final double brightness;
  final double deltaE;
  final String capturedImagePath;
  final String? gradcamImagePath;
  String? certificateNumber;
  final DateTime capturedAt;
  final String sessionId;

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
    DateTime? capturedAt,
    String? sessionId,
  })  : id = id ?? const Uuid().v4(),
        capturedAt = capturedAt ?? DateTime.now(),
        sessionId = sessionId ?? 'SESSION-${DateTime.now().millisecondsSinceEpoch}';

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
        'capturedAt': capturedAt.toIso8601String(),
        'sessionId': sessionId,
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
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        sessionId: json['sessionId'] as String,
      );

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
