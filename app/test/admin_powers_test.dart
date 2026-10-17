import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gemeye/services/api_client.dart';
import 'package:gemeye/services/calibration_service.dart';
import 'package:gemeye/services/device_id_service.dart';
import 'package:gemeye/services/history_service.dart';
import 'package:gemeye/services/storage_service.dart';
import 'phase5c_test.dart' show gradingItem;

/// Phase 10p: the app side of the admin powers (forced sign-out, daily
/// limit, blocked device, calibration reset by support, hidden gradings).

http.Response json(int status, Object body) => http.Response(
    jsonEncode(body), status,
    headers: {'content-type': 'application/json'});

ApiClient clientFor(List<http.Request> sent,
        http.Response Function(http.Request) handler) =>
    ApiClient(
      baseUrl: 'http://api.test',
      tokenProvider: (_) async => 'token',
      client: MockClient((req) async {
        sent.add(req);
        return handler(req);
      }),
    );

CalibrationSession session(String id, {Duration validFor = const Duration(hours: 8)}) =>
    CalibrationSession(
      id: id,
      createdAt: DateTime.now(),
      validUntil: DateTime.now().add(validFor),
      deviceModel: 'Pixel 8',
      ccm: [1, 0, 0, 0, 1, 0, 0, 0, 1],
      residual: 0.2,
      quality: CalibrationQuality.excellent,
      measured: [for (var i = 0; i < 6; i++) [10.0, 20.0, 30.0]],
      perPatchError: List.filled(6, 0.1),
    );

void main() {
  final lost = <ApiException>[];

  setUp(() {
    lost.clear();
    ApiClient.sessionLostHandler = (e) async => lost.add(e);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() => ApiClient.sessionLostHandler = null);

  group('error codes', () {
    test('401 token_revoked is a sign-out, without a token refresh', () async {
      final sent = <http.Request>[];
      final api = clientFor(
          sent,
          (_) => json(401, {
                'status': 'error',
                'code': 'token_revoked',
                'message': 'You were signed out. Please sign in again.',
              }));
      await expectLater(
          api.getJson('/gradings'),
          throwsA(isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.tokenRevoked)
              .having((e) => e.message, 'message',
                  'You were signed out. Please sign in again.')));
      expect(sent, hasLength(1));
      await Future<void>.delayed(Duration.zero);
      expect(lost.single.code, ApiErrorCode.tokenRevoked);
    });

    test('429 DAILY_LIMIT_REACHED has the user message and keeps the session',
        () async {
      final api = clientFor(
          [],
          (_) => json(429, {
                'status': 'error',
                'code': 'DAILY_LIMIT_REACHED',
                'message': 'server text',
              }));
      await expectLater(
          api.postMultipart('/grade', fields: {}, files: () => []),
          throwsA(isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.dailyLimitReached)
              .having((e) => e.message, 'message',
                  'Daily grading limit reached. Try again tomorrow or contact support.')));
      await Future<void>.delayed(Duration.zero);
      expect(lost, isEmpty);
    });

    test('403 DEVICE_BLOCKED has the user message and keeps the session',
        () async {
      final api = clientFor(
          [],
          (_) => json(403, {'status': 'error', 'code': 'DEVICE_BLOCKED'}));
      await expectLater(
          api.postJson('/calibrations', {}),
          throwsA(isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.deviceBlocked)
              .having((e) => e.message, 'message',
                  'This device is blocked. Contact support.')));
      await Future<void>.delayed(Duration.zero);
      expect(lost, isEmpty);
    });

    test('a blocked device is not retried by the calibration queue', () async {
      final s = session('S-2099-01-01-01');
      await CalibrationService.save(s);
      final sent = <http.Request>[];
      final api = clientFor(
          sent, (_) => json(403, {'status': 'error', 'code': 'DEVICE_BLOCKED'}));
      expect(await CalibrationService.syncToServer(s, client: api), isFalse);
      await CalibrationService.syncPending(client: api);
      expect(sent, hasLength(1));
    });
  });

  group('calibration reset by support', () {
    test('an invalidated session is marked expired', () async {
      final s = session('S-2099-01-01-02');
      await CalibrationService.save(s);
      final sent = <http.Request>[];
      final api = clientFor(
          sent,
          (_) => json(200, {
                'session_id': s.id,
                'found': true,
                'invalidated': true,
                'invalidated_at': '2099-01-01T00:00:00Z',
              }));
      expect(await CalibrationService.checkServerReset(client: api), isTrue);
      expect(sent.single.url.path, '/me/calibration-status');
      expect(sent.single.url.queryParameters['session_id'], s.id);
      expect(CalibrationService.isValidNow, isFalse);
      expect((await CalibrationService.current())!.isValid, isFalse);
      final h = await CalibrationService.history();
      expect(h.single.id, s.id);
      expect(h.single.isValid, isFalse);
      // Already expired: nothing more to check.
      expect(await CalibrationService.checkServerReset(client: api), isFalse);
      expect(sent, hasLength(1));
    });

    test('a valid session stays valid; offline is not a reset', () async {
      final s = session('S-2099-01-01-03');
      await CalibrationService.save(s);
      final ok = clientFor(
          [], (_) => json(200, {'found': true, 'invalidated': false}));
      expect(await CalibrationService.checkServerReset(client: ok), isFalse);
      final offline = ApiClient(
        baseUrl: 'http://api.test',
        tokenProvider: (_) async => 'token',
        client: MockClient((_) async => throw const SocketException('down')),
      );
      expect(await CalibrationService.checkServerReset(client: offline),
          isFalse);
      expect(CalibrationService.isValidNow, isTrue);
    });
  });

  test('a grading hidden by an admin disappears from History on refresh',
      () async {
    final api = clientFor([], (req) {
      if (req.url.path == '/certificates') return json(200, {'items': []});
      return json(200, {
        'items': [gradingItem('g1')],
        'next_cursor': null,
      });
    });
    final both = clientFor([], (req) {
      if (req.url.path == '/certificates') return json(200, {'items': []});
      return json(200, {
        'items': [gradingItem('g1'), gradingItem('g2')],
        'next_cursor': null,
      });
    });
    await HistoryService.refresh(client: both);
    expect((await StorageService.getGradeHistory()).map((r) => r.id),
        containsAll(['g1', 'g2']));
    final after = await HistoryService.refresh(client: api);
    expect(after.map((r) => r.id), ['g1']);
    expect((await StorageService.getGradeHistory()).map((r) => r.id), ['g1']);
  });

  group('per-install device id', () {
    test('created once as a UUID v4 and kept in secure storage', () async {
      DeviceIdService.resetForTest();
      final id = await DeviceIdService.init();
      expect(id, matches(RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      DeviceIdService.resetForTest();
      expect(await DeviceIdService.init(), id);
      FlutterSecureStorage.setMockInitialValues({});
      DeviceIdService.resetForTest();
      expect(await DeviceIdService.init(), isNot(id));
    });

    test('every call sends X-Device-Id, public ones too', () async {
      final sent = <http.Request>[];
      final api = ApiClient(
        baseUrl: 'http://api.test',
        tokenProvider: (_) async => 'token',
        deviceId: () => 'install-1',
        client: MockClient((req) async {
          sent.add(req);
          return json(200, {});
        }),
      );
      await api.getJson('/gradings');
      await api.getJson('/config', auth: false);
      await api.postMultipart('/grade', fields: {'device': 'Pixel 8'}, files: () => []);
      expect(sent.map((r) => r.headers['X-Device-Id']), everyElement('install-1'));
    });
  });
}
