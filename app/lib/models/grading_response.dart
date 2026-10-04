import 'grade_result.dart';

/// `status` of a `/grade` response: ok, or the gate that refused the photo.
enum GradingStatus {
  ok('ok'),
  invalidImage('invalid_image'),
  blurry('blurry'),
  noStone('no_stone'),
  notBlue('not_blue'),
  notRecognised('not_recognised'),

  /// A status this app version does not know.
  unknown('unknown');

  final String wire;
  const GradingStatus(this.wire);

  static GradingStatus fromWire(String? s) => GradingStatus.values
      .firstWhere((v) => v.wire == s, orElse: () => GradingStatus.unknown);
}

/// A `/grade` response: a [result] when [isOk], otherwise a rejection with
/// the server's user-facing [message] and the gate [diagnostics].
class GradingResponse {
  final GradingStatus status;

  /// The raw status string from the server.
  final String rawStatus;
  final String? message;
  final List<String> warnings;
  final Map<String, dynamic> diagnostics;
  final GradeResult? result;

  const GradingResponse({
    required this.status,
    required this.rawStatus,
    this.message,
    this.warnings = const [],
    this.diagnostics = const {},
    this.result,
  });

  bool get isOk => status == GradingStatus.ok && result != null;

  /// Measured hue (degrees) for a not_blue rejection.
  double? get measuredHue => (diagnostics['hue_wb'] as num?)?.toDouble();

  factory GradingResponse.fromJson(
    Map<String, dynamic> json, {
    required String capturedImagePath,
    String? sessionId,
  }) {
    final raw = json['status'] as String? ?? 'unknown';
    final status = GradingStatus.fromWire(raw);
    return GradingResponse(
      status: status,
      rawStatus: raw,
      message: json['message'] as String?,
      warnings: (json['warnings'] as List?)?.cast<String>() ?? const [],
      diagnostics:
          (json['diagnostics'] as Map?)?.cast<String, dynamic>() ?? const {},
      result: status == GradingStatus.ok
          ? GradeResult.fromApi(json,
              capturedImagePath: capturedImagePath, sessionId: sessionId)
          : null,
    );
  }
}
