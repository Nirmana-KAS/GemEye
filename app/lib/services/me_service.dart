import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'settings_service.dart';

/// The signed-in user's server profile settings (GET/PUT /me). The server is
/// the source of truth; [SettingsService] keeps a local copy for offline use.
class MeService {
  MeService._();

  /// Reads /me and applies its settings locally. Failures keep the local
  /// values. Returns true when the server answered.
  static Future<bool> sync({ApiClient? client}) async {
    try {
      final json = await (client ?? ApiClient.instance).getJson('/me');
      await apply(json);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Profile settings not loaded: $e');
      return false;
    }
  }

  /// Applies the settings of a /me response.
  static Future<void> apply(Map<String, dynamic> me) async {
    final s = me['settings'] as Map<String, dynamic>? ?? const {};
    final t = (s['referral_threshold'] as num?)?.toDouble();
    if (t != null) {
      await SettingsService.setReferralThreshold(t * 100);
    }
    final show = s['show_name_on_certificates'] as bool?;
    if (show != null) await SettingsService.setShowNameOnCertificates(show);
  }

  /// PUT /me with the given settings. Throws [ApiException].
  static Future<void> updateSettings({
    double? referralThresholdPercent,
    bool? showNameOnCertificates,
    ApiClient? client,
  }) async {
    await (client ?? ApiClient.instance).putJson('/me', {
      'settings': {
        if (referralThresholdPercent != null)
          'referral_threshold':
              double.parse((referralThresholdPercent / 100).toStringAsFixed(2)),
        if (showNameOnCertificates != null)
          'show_name_on_certificates': showNameOnCertificates,
      },
    });
  }

  /// DELETE /me: removes the account and all its server data. Throws
  /// [ApiException] (reauthRequired when the sign-in is older than 5 minutes).
  static Future<void> deleteAccount({ApiClient? client}) =>
      (client ?? ApiClient.instance).delete('/me');
}
