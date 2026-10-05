import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../config/app_config.dart';

/// Why an API call failed.
enum ApiErrorCode {
  accountDeleted,
  reauthRequired,
  maintenance,
  offline,
  timeout,
  serverError,
  tooLarge,

  /// Not signed in, or the token was still refused after one refresh.
  unauthorized,
  notFound,
  badRequest,
  conflict,
}

/// A failed API call. [message] is always safe to show to the user.
class ApiException implements Exception {
  final ApiErrorCode code;
  final String message;
  final int? statusCode;

  const ApiException(this.code, this.message, {this.statusCode});

  @override
  String toString() => 'ApiException(${code.name}, $statusCode)';
}

/// Returns a Firebase ID token, or null when nobody is signed in.
typedef TokenProvider = Future<String?> Function(bool forceRefresh);

/// A request built fresh for every attempt (a request body can be sent once).
typedef RequestBuilder = Future<http.BaseRequest> Function(Uri url);

/// HTTP client for the GemEye API: base URL, Firebase bearer token (refreshed
/// once on 401), timeouts, one automatic retry for GET on timeout or 5xx
/// (never for POST/PUT/DELETE), and typed [ApiException]s.
class ApiClient {
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 60);

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient();

  /// Called once per failed request when the session is dead: the account
  /// was deleted (account_deleted) or the token cannot be refreshed
  /// (unauthorized after the refresh). Set in main.dart to show the
  /// session-expired dialog, clear local data and go to Login.
  static Future<void> Function(ApiException e)? sessionLostHandler;

  static bool _isSessionLost(ApiException e) =>
      e.code == ApiErrorCode.accountDeleted ||
      e.code == ApiErrorCode.unauthorized ||
      e.code == ApiErrorCode.reauthRequired;

  final http.Client _client;
  final TokenProvider _token;
  final String? _baseUrl;

  /// Read on every request, so a server address changed in Settings applies at once.
  String get baseUrl => _baseUrl ?? AppConfig.apiBaseUrl;
  final Duration _receiveTimeout;

  ApiClient({
    http.Client? client,
    TokenProvider? tokenProvider,
    String? baseUrl,
    Duration? receiveTimeout,
  })  : _client = client ??
            IOClient(HttpClient()..connectionTimeout = connectTimeout),
        _token = tokenProvider ?? _firebaseToken,
        _baseUrl = baseUrl,
        _receiveTimeout = receiveTimeout ?? ApiClient.receiveTimeout;

  static Future<String?> _firebaseToken(bool forceRefresh) async =>
      FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);

  Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, String>? query, bool auth = true}) async {
    final r = await send(
        (url) async => http.Request('GET', url), uri(path, query),
        auth: auth, retryable: true);
    return decodeObject(r);
  }

  Future<Map<String, dynamic>> postJson(String path, Object? body,
          {bool auth = true}) =>
      _sendJson('POST', path, body, auth: auth);

  Future<Map<String, dynamic>> putJson(String path, Object? body,
          {bool auth = true}) =>
      _sendJson('PUT', path, body, auth: auth);

  /// DELETE. [guardSession] false: the caller handles session errors itself
  /// (account deletion).
  Future<void> delete(String path, {bool guardSession = true}) async {
    await send((url) async => http.Request('DELETE', url), uri(path),
        guardSession: guardSession);
  }

  /// Multipart POST. [files] is called again for each attempt.
  /// [onProgress] reports the request bytes handed to the connection.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> Function() files,
    void Function(int sent, int total)? onProgress,
  }) async {
    final r = await send((url) async {
      final req = http.MultipartRequest('POST', url)
        ..fields.addAll(fields)
        ..files.addAll(files());
      return onProgress == null ? req : _ProgressRequest(req, onProgress);
    }, uri(path));
    return decodeObject(r);
  }

  Future<Map<String, dynamic>> _sendJson(String method, String path,
      Object? body,
      {bool auth = true}) async {
    final r = await send((url) async {
      final req = http.Request(method, url)
        ..headers['Content-Type'] = 'application/json';
      if (body != null) req.body = jsonEncode(body);
      return req;
    }, uri(path), auth: auth);
    return decodeObject(r);
  }

  /// Sends the request built by [build]. On 401 (other than account_deleted
  /// and reauth_required) the token is refreshed once and the request sent
  /// once more. [retryable] (GET only) also retries once on timeout or 5xx.
  Future<http.Response> send(RequestBuilder build, Uri url,
      {bool auth = true,
      bool retryable = false,
      bool guardSession = true}) async {
    try {
      return await _send(build, url, auth: auth, retryable: retryable);
    } on ApiException catch (e) {
      if (auth && guardSession && _isSessionLost(e)) {
        final handler = sessionLostHandler;
        if (handler != null) unawaited(handler(e));
      }
      rethrow;
    }
  }

  Future<http.Response> _send(RequestBuilder build, Uri url,
      {required bool auth, required bool retryable}) async {
    var refreshed = false;
    var retried = false;
    while (true) {
      http.Response r;
      try {
        r = await _attempt(build, url, auth: auth, forceRefresh: refreshed);
      } on ApiException catch (e) {
        if (retryable && !retried && e.code == ApiErrorCode.timeout) {
          retried = true;
          continue;
        }
        rethrow;
      }
      if (r.statusCode >= 200 && r.statusCode < 300) return r;

      final e = errorFor(r);
      if (auth &&
          r.statusCode == 401 &&
          e.code == ApiErrorCode.unauthorized &&
          !refreshed) {
        refreshed = true;
        continue;
      }
      if (retryable && !retried && r.statusCode >= 500 &&
          e.code != ApiErrorCode.maintenance) {
        retried = true;
        continue;
      }
      throw e;
    }
  }

  Future<http.Response> _attempt(RequestBuilder build, Uri url,
      {required bool auth, required bool forceRefresh}) async {
    final req = await build(url);
    req.headers['Accept'] = 'application/json';
    if (auth) {
      String? token;
      try {
        token = await _token(forceRefresh);
      } catch (e) {
        if (kDebugMode) debugPrint('ID token failed: $e');
        if (_isNetworkError(e)) {
          throw const ApiException(ApiErrorCode.offline, _offlineMessage);
        }
      }
      if (token == null) {
        throw const ApiException(
            ApiErrorCode.unauthorized, _unauthorizedMessage,
            statusCode: 401);
      }
      req.headers['Authorization'] = 'Bearer $token';
    }
    try {
      final streamed = await _client.send(req).timeout(_receiveTimeout);
      return await http.Response.fromStream(streamed).timeout(_receiveTimeout);
    } on TimeoutException {
      throw const ApiException(ApiErrorCode.timeout,
          'The server is taking too long. Please try again.');
    } catch (e) {
      if (kDebugMode) debugPrint('Request failed: $e');
      if (_isNetworkError(e)) {
        throw const ApiException(ApiErrorCode.offline, _offlineMessage);
      }
      throw const ApiException(ApiErrorCode.serverError, _serverMessage);
    }
  }

  static bool _isNetworkError(Object e) =>
      e is SocketException ||
      e is http.ClientException ||
      e is HandshakeException ||
      (e is FirebaseException && e.code == 'network-request-failed');

  static const String _offlineMessage =
      'No internet connection. Check your connection and try again.';
  static const String _serverMessage =
      'Something went wrong on our side. Please try again later.';
  static const String _unauthorizedMessage =
      'Your session has expired. Please sign in again.';

  /// Maps an error response to an [ApiException] with a user-friendly message.
  static ApiException errorFor(http.Response r) {
    String? code;
    String? serverMessage;
    try {
      final body = jsonDecode(r.body);
      if (body is Map<String, dynamic>) {
        code = body['code'] as String?;
        serverMessage = body['message'] as String?;
      }
    } catch (_) {}
    final s = r.statusCode;
    if (code == 'account_deleted') {
      return ApiException(ApiErrorCode.accountDeleted,
          'This account has been deleted.', statusCode: s);
    }
    if (code == 'reauth_required') {
      return ApiException(ApiErrorCode.reauthRequired,
          'Please sign in again to continue.', statusCode: s);
    }
    if (code == 'maintenance') {
      // The maintenance message is written for users (remote config).
      return ApiException(
          ApiErrorCode.maintenance,
          (serverMessage?.trim().isNotEmpty ?? false)
              ? serverMessage!.trim()
              : 'GemEye is under maintenance. Please try again later.',
          statusCode: s);
    }
    if (code == 'duplicate_request') {
      return ApiException(ApiErrorCode.conflict,
          'This request was already used. Please try again.', statusCode: s);
    }
    return switch (s) {
      401 => ApiException(ApiErrorCode.unauthorized, _unauthorizedMessage,
          statusCode: s),
      404 => ApiException(ApiErrorCode.notFound, 'Not found.', statusCode: s),
      409 => ApiException(ApiErrorCode.conflict,
          'This was already done. Please refresh.', statusCode: s),
      413 => ApiException(ApiErrorCode.tooLarge,
          'This photo is too large. Please use a smaller photo.',
          statusCode: s),
      >= 500 =>
        ApiException(ApiErrorCode.serverError, _serverMessage, statusCode: s),
      _ => ApiException(ApiErrorCode.badRequest,
          'The request could not be completed. Please try again.',
          statusCode: s),
    };
  }

  /// Decodes a JSON object body; anything else is a server error.
  static Map<String, dynamic> decodeObject(http.Response r) {
    if (r.body.isEmpty) return <String, dynamic>{};
    try {
      final body = jsonDecode(r.body);
      if (body is Map<String, dynamic>) return body;
    } catch (_) {}
    throw ApiException(ApiErrorCode.serverError, _serverMessage,
        statusCode: r.statusCode);
  }
}

/// Wraps a request and counts its body bytes as the connection reads them
/// (the stream is pulled with back-pressure, so this follows the upload).
class _ProgressRequest extends http.BaseRequest {
  final http.ByteStream _body;
  final int _total;
  final void Function(int sent, int total) _onProgress;

  _ProgressRequest(http.BaseRequest inner, this._onProgress)
      : _total = inner.contentLength ?? -1,
        _body = inner.finalize(),
        super(inner.method, inner.url) {
    headers.addAll(inner.headers);
    contentLength = inner.contentLength;
  }

  @override
  http.ByteStream finalize() {
    super.finalize();
    var sent = 0;
    return http.ByteStream(_body.map((chunk) {
      sent += chunk.length;
      _onProgress(sent, _total);
      return chunk;
    }));
  }
}
