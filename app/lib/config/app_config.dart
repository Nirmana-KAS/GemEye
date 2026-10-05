/// Build-time API configuration.
///
/// `--dart-define=API_BASE_URL=http://<PC-IP>:8000` overrides everything (local
/// demo over Wi-Fi). Otherwise `--dart-define API_ENV=dev|prod` picks the URL.
///
/// dev (default): the local Docker server. On an Android emulator or a USB
/// device, forward the port first: `adb reverse tcp:8000 tcp:8000`.
/// Cleartext HTTP is currently allowed on Android for the local demo (see
/// android/app/src/main/res/xml/network_security_config.xml).
class AppConfig {
  static const String apiEnv =
      String.fromEnvironment('API_ENV', defaultValue: 'dev');

  /// Explicit base URL override; empty when not set.
  static const String apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL');

  static const String DEV_URL = 'http://127.0.0.1:8000'; // ignore: constant_identifier_names

  /// Placeholder until the production API is deployed (HTTPS only).
  static const String PROD_URL = 'https://api.gemeye.invalid'; // ignore: constant_identifier_names

  static bool get isProd => apiEnv == 'prod';

  static String get apiBaseUrl {
    if (apiBaseUrlOverride.isNotEmpty) {
      return apiBaseUrlOverride.endsWith('/')
          ? apiBaseUrlOverride.substring(0, apiBaseUrlOverride.length - 1)
          : apiBaseUrlOverride;
    }
    return isProd ? PROD_URL : DEV_URL;
  }
}
