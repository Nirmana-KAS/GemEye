import '../models/app_notification.dart';
import '../models/grade_result.dart';
import '../widgets/confidence_badge.dart';
import 'certificate_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Saving graded stones and preparing them for certificate export.
class GradeRecordService {
  static const String placeholderStoneId = 'GE-STONE-00000';

  /// Gives a placeholder result a real stone ID.
  static Future<GradeResult> ensureStoneId(GradeResult r) async {
    if (r.stoneId != placeholderStoneId) return r;
    return r.withStoneId(await StorageService.getNextStoneId());
  }

  /// Saves the result; borderline results also raise a "Stone referred"
  /// notification. Returns the saved result.
  static Future<GradeResult> save(GradeResult r) async {
    final result = await ensureStoneId(r);
    await StorageService.saveGradeResult(result);
    if (result.confidence < ConfidenceBadge.referThreshold) {
      await NotificationService.add(
        type: AppNotificationType.warning,
        title: 'Stone referred',
        message: '${result.stoneId} is borderline '
            '(${result.confidence.round()}%). Gemologist review recommended.',
        action: AppNotificationAction.openResult,
        payload: result.stoneId,
      );
    }
    return result;
  }

  /// Saves the result with a certificate number. A stone that was exported
  /// before keeps its existing number.
  static Future<GradeResult> prepareCertificate(GradeResult r) async {
    final result = await ensureStoneId(r);
    result.certificateNumber ??=
        await CertificateService.generateCertificateNumber();
    await StorageService.saveGradeResult(result);
    return result;
  }
}
