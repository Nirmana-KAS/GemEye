import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Default certificate export format.
enum ExportFormat {
  pdf('PDF'),
  image('Image'),
  both('Both');

  final String label;
  const ExportFormat(this.label);
}

/// Notification categories the user can switch off in Settings.
enum NotificationCategory { calibration, referral, certificate }

/// App preferences (SharedPreferences, not sensitive). Loaded once at
/// startup by [init]; every screen reads the live [ValueNotifier]s so a
/// change in Settings applies everywhere immediately.
class SettingsService {
  SettingsService._();

  static const double defaultReferralThreshold = 60;
  static const double minReferralThreshold = 40;
  static const double maxReferralThreshold = 90;

  static const String _thresholdKey = 'referral_threshold';
  static const String _exportFormatKey = 'export_format_v2';
  static const String _showNameKey = 'show_name_on_certificates';
  static const String _autoSaveKey = 'auto_save_images';
  static const String _notifyCalibrationKey = 'notify_calibration';
  static const String _notifyReferralKey = 'notify_referral';
  static const String _notifyCertificateKey = 'notify_certificate';

  /// Stones below this confidence (%) are "Referred" / borderline.
  static final ValueNotifier<double> referralThreshold =
      ValueNotifier(defaultReferralThreshold);
  static final ValueNotifier<ExportFormat> exportFormat =
      ValueNotifier(ExportFormat.pdf);

  /// Show my name/company on the public certificate page (server setting,
  /// off by default).
  static final ValueNotifier<bool> showNameOnCertificates =
      ValueNotifier(false);
  static final ValueNotifier<bool> autoSavePhotos = ValueNotifier(false);
  static final ValueNotifier<bool> notifyCalibration = ValueNotifier(true);
  static final ValueNotifier<bool> notifyReferral = ValueNotifier(true);
  static final ValueNotifier<bool> notifyCertificate = ValueNotifier(true);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      referralThreshold.value = (prefs.getDouble(_thresholdKey) ??
              defaultReferralThreshold)
          .clamp(minReferralThreshold, maxReferralThreshold);
      exportFormat.value = ExportFormat.values.firstWhere(
        (f) => f.name == prefs.getString(_exportFormatKey),
        orElse: () => ExportFormat.pdf,
      );
      showNameOnCertificates.value = prefs.getBool(_showNameKey) ?? false;
      autoSavePhotos.value = prefs.getBool(_autoSaveKey) ?? false;
      notifyCalibration.value = prefs.getBool(_notifyCalibrationKey) ?? true;
      notifyReferral.value = prefs.getBool(_notifyReferralKey) ?? true;
      notifyCertificate.value = prefs.getBool(_notifyCertificateKey) ?? true;
    } catch (e) {
      if (kDebugMode) debugPrint('SettingsService.init failed: $e');
    }
  }

  static Future<void> _write(
      Future<bool> Function(SharedPreferences p) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (e) {
      if (kDebugMode) debugPrint('SettingsService write failed: $e');
    }
  }

  static Future<void> setReferralThreshold(double v) async {
    referralThreshold.value =
        v.clamp(minReferralThreshold, maxReferralThreshold).roundToDouble();
    await _write((p) => p.setDouble(_thresholdKey, referralThreshold.value));
  }

  static Future<void> setExportFormat(ExportFormat f) async {
    exportFormat.value = f;
    await _write((p) => p.setString(_exportFormatKey, f.name));
  }

  static Future<void> setShowNameOnCertificates(bool v) async {
    showNameOnCertificates.value = v;
    await _write((p) => p.setBool(_showNameKey, v));
  }

  static Future<void> setAutoSavePhotos(bool v) async {
    autoSavePhotos.value = v;
    await _write((p) => p.setBool(_autoSaveKey, v));
  }

  static ValueNotifier<bool> notifierFor(NotificationCategory c) =>
      switch (c) {
        NotificationCategory.calibration => notifyCalibration,
        NotificationCategory.referral => notifyReferral,
        NotificationCategory.certificate => notifyCertificate,
      };

  static Future<void> setNotify(NotificationCategory c, bool v) async {
    notifierFor(c).value = v;
    final key = switch (c) {
      NotificationCategory.calibration => _notifyCalibrationKey,
      NotificationCategory.referral => _notifyReferralKey,
      NotificationCategory.certificate => _notifyCertificateKey,
    };
    await _write((p) => p.setBool(key, v));
  }

  static bool isEnabled(NotificationCategory c) => notifierFor(c).value;

  /// True when [confidence] (%) is below the referral threshold.
  static bool isReferred(double confidence) =>
      confidence < referralThreshold.value;
}
