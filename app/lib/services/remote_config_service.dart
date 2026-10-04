import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import 'api_client.dart';

/// Server blur gate (`app/gates.py`), used until `/config` has been read.
const double kDefaultBlurMinVariance = 29.474166117400628;

/// Remote config from `GET /config` (public). Defaults apply until the first
/// successful fetch, and when the server cannot be reached.
class RemoteConfigService {
  RemoteConfigService._();

  /// Bumped after every successful fetch, so banners can rebuild.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static double blurMinVariance = kDefaultBlurMinVariance;
  static bool gradcamEnabled = false;
  static bool repeatabilityEnabled = true;
  static String minAppVersion = '';
  static bool sessionMapping = false;
  static bool maintenance = false;
  static String maintenanceMessage = '';

  /// Fetches `/config`; failures keep the current values.
  static Future<void> refresh({ApiClient? client}) async {
    try {
      final json =
          await (client ?? ApiClient.instance).getJson('/config', auth: false);
      apply(json);
    } catch (e) {
      if (kDebugMode) debugPrint('Remote config not loaded: $e');
    }
  }

  static void apply(Map<String, dynamic> json) {
    final features = json['features'] as Map<String, dynamic>? ?? const {};
    final m = json['maintenance'] as Map<String, dynamic>? ?? const {};
    blurMinVariance =
        (json['blur_min_variance'] as num?)?.toDouble() ?? kDefaultBlurMinVariance;
    gradcamEnabled = features['gradcam'] as bool? ?? false;
    repeatabilityEnabled = features['repeatability_mode'] as bool? ?? true;
    minAppVersion = json['min_app_version'] as String? ?? '';
    sessionMapping = features['session_mapping'] as bool? ?? false;
    maintenance = m['enabled'] as bool? ?? false;
    maintenanceMessage = m['message'] as String? ?? '';
    changes.value++;
  }

  /// True when this app is older than the server's min_app_version.
  static bool get updateRequired =>
      minAppVersion.isNotEmpty &&
      compareVersions(AppConstants.appVersion, minAppVersion) < 0;

  /// Compares dotted versions numerically ("1.0" equals "1.0.0").
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();
    final x = parts(a), y = parts(b);
    for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d < 0 ? -1 : 1;
    }
    return 0;
  }
}
