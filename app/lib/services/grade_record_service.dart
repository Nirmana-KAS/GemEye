import '../models/app_notification.dart';
import '../models/grade_result.dart';
import 'certificate_api_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';

/// Saving graded stones and preparing them for certificate export.
class GradeRecordService {
  /// Keeps the result (and its photo path) in the local cache; the server
  /// already stored the grading. A referred result also raises a "Stone
  /// referred" notification. Returns the saved result.
  static Future<GradeResult> save(GradeResult result) async {
    await StorageService.saveGradeResult(result);
    if (result.isReferred) {
      await NotificationService.add(
        type: AppNotificationType.warning,
        title: 'Stone referred',
        message: '${result.stoneId} is borderline '
            '(${result.confidence.round()}%). Gemologist review recommended.',
        action: AppNotificationAction.openResult,
        payload: result.stoneId,
        category: NotificationCategory.referral,
      );
    }
    return result;
  }

  /// Gets the server certificate for the stone (issued on the first export,
  /// the same number on every re-export). Throws [ApiException].
  static Future<GradeResult> prepareCertificate(GradeResult r) =>
      CertificateApiService.ensure(r);
}
