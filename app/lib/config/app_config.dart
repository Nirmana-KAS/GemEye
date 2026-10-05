import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API configuration.
///
/// Order: the server address saved in Settings (local demo), then
/// `--dart-define=API_BASE_URL=http://<PC-IP>:8000`, then
/// `--dart-define API_ENV=dev|prod`.
///
/// dev (default): http://127.0.0.1:8000, reached through `adb reverse
/// tcp:8000 tcp:8000` (works over USB and over wireless debugging).
/// Cleartext HTTP is currently allowed on Android for the local demo (see
/// android/app/src/main/res/xml/network_security_config.xml).
class AppConfig {
  static const String apiEnv =
      String.fromEnvironment('API_ENV', defaultValue: 'dev');

  /// Build-time base URL override; empty when not set.
  static const String apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL');

  static const String DEV_URL = 'http://127.0.0.1:8000'; // ignore: constant_identifier_names

  /// Placeholder until the production API is deployed (HTTPS only).
  static const String PROD_URL = 'https://api.gemeye.invalid'; // ignore: constant_identifier_names

  static const String _savedUrlKey = 'api_base_url_saved';

  /// Server address saved in Settings; null when not set.
  static String? _savedUrl;

  static bool get isProd => apiEnv == 'prod';

  /// URL from the build (dart-define or API_ENV), ignoring Settings.
  static String get buildBaseUrl {
    if (apiBaseUrlOverride.isNotEmpty) return _trim(apiBaseUrlOverride);
    return isProd ? PROD_URL : DEV_URL;
  }

  static String get apiBaseUrl => _savedUrl ?? buildBaseUrl;

  static bool get hasSavedUrl => _savedUrl != null;

  static String _trim(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  /// Normalises user input: adds http:// and (for http) :8000 when missing.
  /// Returns null when the text is not a valid http(s) address.
  static String? normalise(String input) {
    var t = input.trim();
    if (t.isEmpty) return null;
    if (!t.startsWith('http://') && !t.startsWith('https://')) t = 'http://$t';
    final uri = Uri.tryParse(_trim(t));
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.path.isNotEmpty || uri.hasQuery) return null;
    if (uri.hasPort) return '${uri.scheme}://${uri.host}:${uri.port}';
    return uri.scheme == 'http'
        ? 'http://${uri.host}:8000'
        : '${uri.scheme}://${uri.host}';
  }

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedUrl = prefs.getString(_savedUrlKey);
    } catch (e) {
      if (kDebugMode) debugPrint('AppConfig.load failed: $e');
    }
  }

  /// Saves [url] (already normalised), or clears it when null.
  static Future<void> saveUrl(String? url) async {
    _savedUrl = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url == null) {
        await prefs.remove(_savedUrlKey);
      } else {
        await prefs.setString(_savedUrlKey, url);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AppConfig.saveUrl failed: $e');
    }
  }
}
