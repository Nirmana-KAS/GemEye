/// Build-time API configuration, chosen with `--dart-define API_ENV=dev|prod`.
///
/// dev (default): the local Docker server. On an Android emulator or a USB
/// device, forward the port first: `adb reverse tcp:8000 tcp:8000`. Cleartext
/// HTTP is allowed only for 127.0.0.1 and localhost, and only in debug builds
/// (android/app/src/debug).
class AppConfig {
  static const String apiEnv =
      String.fromEnvironment('API_ENV', defaultValue: 'dev');

  static const String DEV_URL = 'http://127.0.0.1:8000'; // ignore: constant_identifier_names

  /// Placeholder until the production API is deployed (HTTPS only).
  static const String PROD_URL = 'https://api.gemeye.invalid'; // ignore: constant_identifier_names

  static bool get isProd => apiEnv == 'prod';

  static String get apiBaseUrl => isProd ? PROD_URL : DEV_URL;
}
