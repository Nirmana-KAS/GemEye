import '../models/grade_result.dart';

/// No network connection while grading.
class GradingNoConnectionException implements Exception {
  const GradingNoConnectionException();
}

/// The grading server did not respond in time.
class GradingTimeoutException implements Exception {
  const GradingTimeoutException();
}

/// Any other grading failure.
class GradingException implements Exception {
  final String message;
  const GradingException(this.message);

  @override
  String toString() => 'GradingException: $message';
}

/// Why the server refused to grade a photo.
enum RejectionReason {
  noStone('no_stone'),
  notBlue('not_blue'),
  notRecognised('not_recognised');

  final String status;
  const RejectionReason(this.status);

  /// Maps a server status string; unknown values count as not recognised.
  static RejectionReason fromStatus(String status) => RejectionReason.values
      .firstWhere((r) => r.status == status,
          orElse: () => RejectionReason.notRecognised);
}

/// The photo failed the stone / colour / recognition checks.
class GradingRejectedException implements Exception {
  final RejectionReason reason;

  /// Measured hue in degrees, sent with [RejectionReason.notBlue].
  final double? measuredHue;

  const GradingRejectedException(this.reason, {this.measuredHue});
}

/// Sends a cropped, calibrated photo for grading.
class GradingService {
  /// Grades one photo. Throws [GradingNoConnectionException],
  /// [GradingTimeoutException], [GradingRejectedException] or
  /// [GradingException].
  static Future<GradeResult> grade({
    required String imagePath,
    required String stoneId,
    required String sessionId,
  }) async {
    // TODO(backend): POST the photo and the session CCM to
    // AppConstants.apiBaseUrl + gradeEndpoint with the http package.
    // Throw GradingNoConnectionException on SocketException,
    // GradingTimeoutException on TimeoutException, GradingRejectedException
    // with RejectionReason.fromStatus(status) on a rejection status, and
    // GradingException on any other error. Until then this returns the
    // existing demo result.
    return GradeResult(
      stoneId: stoneId,
      gradeNumber: 3,
      gradeName: 'Vivid',
      tradeName: 'Royal Blue',
      confidence: 92.4,
      uncertaintyRange: 0.2,
      labL: 42.3,
      labA: 8.9,
      labB: -27.0,
      labC: 28.4,
      hue: 228,
      saturation: 88,
      brightness: 62,
      deltaE: 1.2,
      capturedImagePath: imagePath,
      sessionId: sessionId,
    );
  }
}
