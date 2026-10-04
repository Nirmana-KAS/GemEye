import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gemeye/services/api_client.dart';

/// Fake token source: "token-N", N = number of forced refreshes so far.
class FakeTokens {
  int calls = 0;
  int refreshes = 0;

  Future<String?> call(bool forceRefresh) async {
    calls++;
    if (forceRefresh) refreshes++;
    return 'token-$refreshes';
  }
}

http.Response json(int status, Object body) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

void main() {
  late FakeTokens tokens;
  late List<http.Request> sent;

  ApiClient clientFor(FutureOr<http.Response> Function(http.Request) handler,
      {Duration? receiveTimeout}) {
    sent = [];
    return ApiClient(
      baseUrl: 'http://api.test',
      tokenProvider: tokens.call,
      receiveTimeout: receiveTimeout,
      client: MockClient((req) async {
        sent.add(req);
        return handler(req);
      }),
    );
  }

  setUp(() => tokens = FakeTokens());

  test('sends the bearer token', () async {
    final api = clientFor((_) => json(200, {'ok': true}));
    expect(await api.getJson('/me'), {'ok': true});
    expect(sent.single.headers['Authorization'], 'Bearer token-0');
    expect(sent.single.url.toString(), 'http://api.test/me');
  });

  test('401 refreshes the token once and retries once', () async {
    final api = clientFor((req) => req.headers['Authorization'] == 'Bearer token-0'
        ? json(401, {'status': 'error', 'detail': 'Authentication required.'})
        : json(200, {'uid': 'u1'}));
    expect(await api.getJson('/me'), {'uid': 'u1'});
    expect(sent, hasLength(2));
    expect(tokens.refreshes, 1);
    expect(sent.last.headers['Authorization'], 'Bearer token-1');
  });

  test('POST is also retried once after a token refresh', () async {
    final api = clientFor((req) => req.headers['Authorization'] == 'Bearer token-0'
        ? json(401, {'status': 'error', 'detail': 'Authentication required.'})
        : json(201, {'feedback_id': 'f1'}));
    expect(await api.postJson('/feedback', {'rating': 5}), {'feedback_id': 'f1'});
    expect(sent, hasLength(2));
    expect(jsonDecode(sent.last.body), {'rating': 5});
  });

  test('401 twice gives unauthorized after a single refresh', () async {
    final api = clientFor(
        (_) => json(401, {'status': 'error', 'detail': 'Authentication required.'}));
    await expectLater(
        api.getJson('/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.unauthorized)));
    expect(sent, hasLength(2));
    expect(tokens.refreshes, 1);
  });

  test('account_deleted is not retried', () async {
    final api = clientFor((_) => json(401, {
          'status': 'error',
          'code': 'account_deleted',
          'detail': 'This account has been deleted.',
        }));
    await expectLater(
        api.postJson('/feedback', {}),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.accountDeleted)));
    expect(sent, hasLength(1));
    expect(tokens.refreshes, 0);
  });

  test('reauth_required is not retried', () async {
    final api = clientFor((_) => json(401, {
          'status': 'error',
          'code': 'reauth_required',
          'detail': 'Please sign in again to delete your account.',
        }));
    await expectLater(
        api.delete('/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.reauthRequired)));
    expect(sent, hasLength(1));
  });

  test('maintenance uses the server message and is not retried', () async {
    final api = clientFor((_) => json(503, {
          'status': 'error',
          'code': 'maintenance',
          'message': 'Back at 10:00',
          'detail': 'Back at 10:00',
        }));
    await expectLater(
        api.getJson('/gradings'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.maintenance)
            .having((e) => e.message, 'message', 'Back at 10:00')));
    expect(sent, hasLength(1));
  });

  test('GET retries once on 5xx', () async {
    var n = 0;
    final api = clientFor((_) => ++n == 1
        ? json(500, {'status': 'error', 'detail': 'Internal server error.'})
        : json(200, {'items': []}));
    expect(await api.getJson('/gradings'), {'items': []});
    expect(sent, hasLength(2));
  });

  test('GET gives server_error after two 5xx', () async {
    final api = clientFor((_) => json(502, {'detail': 'x'}));
    await expectLater(
        api.getJson('/gradings'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.serverError)));
    expect(sent, hasLength(2));
  });

  test('POST is never retried on 5xx', () async {
    final api = clientFor((_) => json(500, {'detail': 'x'}));
    await expectLater(
        api.postJson('/feedback', {}),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.serverError)));
    expect(sent, hasLength(1));
  });

  test('GET retries once on timeout, POST does not', () async {
    var n = 0;
    final api = clientFor((_) async {
      if (++n == 1) await Future<void>.delayed(const Duration(seconds: 1));
      return json(200, {'ok': true});
    }, receiveTimeout: const Duration(milliseconds: 50));
    expect(await api.getJson('/config', auth: false), {'ok': true});
    expect(sent, hasLength(2));

    final slow = clientFor((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return json(200, {});
    }, receiveTimeout: const Duration(milliseconds: 50));
    await expectLater(
        slow.postJson('/feedback', {}),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.timeout)));
    expect(sent, hasLength(1));
  });

  test('network error is offline', () async {
    final api = clientFor((_) => throw const SocketException('down'));
    await expectLater(
        api.getJson('/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.offline)));
  });

  test('413 is too_large', () async {
    final api = clientFor((_) => json(413, {'detail': 'Image is larger than 15 MB.'}));
    await expectLater(
        api.postMultipart('/grade', fields: {}, files: () => []),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.tooLarge)));
  });

  test('no signed-in user is unauthorized without a request', () async {
    sent = [];
    final api = ApiClient(
      baseUrl: 'http://api.test',
      tokenProvider: (_) async => null,
      client: MockClient((req) async {
        sent.add(req);
        return json(200, {});
      }),
    );
    await expectLater(
        api.getJson('/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.unauthorized)));
    expect(sent, isEmpty);
  });

  test('public calls send no token', () async {
    final api = clientFor((_) => json(200, {'status': 'ok'}));
    await api.getJson('/health', auth: false);
    expect(sent.single.headers.containsKey('Authorization'), isFalse);
    expect(tokens.calls, 0);
  });
}
