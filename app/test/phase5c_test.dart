import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gemeye/models/grade_result.dart';
import 'package:gemeye/services/api_client.dart';
import 'package:gemeye/services/calibration_service.dart';
import 'package:gemeye/services/certificate_api_service.dart';
import 'package:gemeye/services/history_service.dart';
import 'package:gemeye/services/me_service.dart';
import 'package:gemeye/services/remote_config_service.dart';
import 'package:gemeye/services/settings_service.dart';

http.Response json(int status, Object body) => http.Response(
    jsonEncode(body), status,
    headers: {'content-type': 'application/json'});

ApiClient clientFor(List<http.Request> sent,
    http.Response Function(http.Request) handler) {
  return ApiClient(
    baseUrl: 'http://api.test',
    tokenProvider: (_) async => 't',
    client: MockClient((req) async {
      sent.add(req);
      return handler(req);
    }),
  );
}

Map<String, dynamic> gradingItem(String id, {bool referred = false}) => {
      'grading_id': id,
      'stone_id': 'GE-STONE-$id',
      'created_at': '2026-10-05T04:00:00Z',
      'status': 'ok',
      'calibration_session_id': 'S-2026-10-05-01',
      'image_url': 'http://img/$id',
      'result': {
        'status': 'ok',
        'grade': 4,
        'grade_name': 'Intense',
        'trade_name': 'Intense Cornflower',
        'confidence': 0.91,
        'uncertainty': 0.3,
        'referred': referred,
        'probabilities': [0, 0, 0.05, 0.91, 0.04, 0, 0],
        'colour': {
          'L': 30.0, 'a': 5.0, 'b': -40.0, 'C': 40.0, 'H': 277.0,
          'S': 80.0, 'B': 50.0, 'hex': '#2A408C', 'ciecam02': null,
          'approximate': false,
        },
        'delta_e00_to_typical': 1.2,
      },
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('history filters map to GET /gradings query params', () {
    final q = HistoryService.query(
      cursor: 'abc',
      grade: 3,
      referred: true,
      from: DateTime.utc(2026, 10, 1),
      to: DateTime.utc(2026, 10, 5, 23, 59, 59),
    );
    expect(q, {
      'limit': '50',
      'cursor': 'abc',
      'grade': '3',
      'referred': 'true',
      'from': '2026-10-01T00:00:00.000Z',
      'to': '2026-10-05T23:59:59.000Z',
    });
    expect(HistoryService.query(), {'limit': '50'});
  });

  test('a grading item becomes a GradeResult', () {
    final r = GradeResult.fromGradingItem(gradingItem('g1', referred: true));
    expect(r.gradingId, 'g1');
    expect(r.id, 'g1');
    expect(r.stoneId, 'GE-STONE-g1');
    expect(r.gradeNumber, 4);
    expect(r.confidence, closeTo(91, 1e-9));
    expect(r.sessionId, 'S-2026-10-05-01');
    expect(r.imageUrl, 'http://img/g1');
    expect(r.referred, true);
    expect(r.isReferred, true);
    expect(r.capturedAt.toUtc(), DateTime.utc(2026, 10, 5, 4));
  });

  test('isReferred uses the server flag, else the threshold', () {
    final server = GradeResult.fromGradingItem(gradingItem('g1'));
    expect(server.isReferred, false);
    final json = gradingItem('g2');
    (json['result'] as Map).remove('referred');
    final old = GradeResult.fromGradingItem(json);
    SettingsService.referralThreshold.value = 95;
    expect(old.isReferred, true);
    SettingsService.referralThreshold.value = 60;
    expect(old.isReferred, false);
  });

  test('calibration body: 3x3 ccm, 6 patches in order', () {
    final s = CalibrationSession(
      id: 'S-2026-10-05-01',
      createdAt: DateTime.utc(2026, 10, 5),
      validUntil: DateTime.utc(2026, 10, 5, 8),
      deviceModel: 'Pixel',
      ccm: [1, 2, 3, 4, 5, 6, 7, 8, 9],
      residual: 0.25,
      quality: CalibrationQuality.excellent,
      measured: [
        for (var i = 0; i < 6; i++) [i * 10.0, i * 10.0 + 1, i * 10.0 + 2]
      ],
      perPatchError: List.filled(6, 0.1),
    );
    final b = CalibrationService.serverBody(s);
    expect(b['session_id'], 'S-2026-10-05-01');
    expect(b['ccm'], [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9]
    ]);
    expect(b['measured_patches'], hasLength(6));
    expect((b['measured_patches'] as List).first, [0.0, 1.0, 2.0]);
    expect(b['quality'], 'excellent');
    expect(b['valid_until'], '2026-10-05T08:00:00.000Z');
    expect(b['device'], 'Pixel');
  });

  group('certificates', () {
    GradeResult stone({String? certNo}) {
      final r = GradeResult.fromGradingItem(gradingItem('g1'));
      r.certificateNumber = certNo;
      return r;
    }

    Map<String, dynamic> cert({
      String status = 'valid',
      String grading = 'g1',
      Map<String, dynamic>? owner,
    }) =>
        {
          'cert_no': 'GE-202610-00001',
          'grading_id': grading,
          'status': status,
          'verify_url': 'https://v.test/v/abc',
          'owner': owner,
        };

    test('first export issues one with POST, then reads it with GET',
        () async {
      final sent = <http.Request>[];
      final api = clientFor(
          sent,
          (req) => req.method == 'POST'
              ? json(201, {
                  'cert_no': 'GE-202610-00001',
                  'verify_url': 'https://v.test/v/abc',
                  'issued_at': '2026-10-05T04:00:00Z',
                })
              : json(200, cert()));
      final r = await CertificateApiService.ensure(stone(), client: api);
      expect(sent.map((q) => q.method), ['POST', 'GET']);
      expect(sent.first.url.path, '/certificates');
      expect(jsonDecode(sent.first.body), {'grading_id': 'g1'});
      expect(r.certificateNumber, 'GE-202610-00001');
      expect(r.certificateVerifyUrl, 'https://v.test/v/abc');
      expect(r.certificateOwnerName, isNull);
    });

    test('re-export reads the same certificate with GET only', () async {
      final sent = <http.Request>[];
      final api = clientFor(sent, (_) => json(200, cert()));
      final r = await CertificateApiService.ensure(
          stone(certNo: 'GE-202610-00001'),
          client: api);
      expect(sent.single.method, 'GET');
      expect(sent.single.url.path, '/certificates/GE-202610-00001');
      expect(r.certificateNumber, 'GE-202610-00001');
      expect(r.certificateVerifyUrl, 'https://v.test/v/abc');
    });

    test('owner fields come from the certificate, not the toggle', () async {
      final api = clientFor(
          [],
          (_) => json(200,
              cert(owner: {'display_name': 'Nirmana', 'company': 'Orava'})));
      final r = await CertificateApiService.ensure(
          stone(certNo: 'GE-202610-00001'),
          client: api);
      expect(r.certificateOwnerName, 'Nirmana');
      expect(r.certificateOwnerCompany, 'Orava');
      final back = GradeResult.fromJson(r.toJson());
      expect(back.certificateOwnerName, 'Nirmana');
      expect(back.certificateOwnerCompany, 'Orava');
    });

    test('a revoked certificate cannot be exported again', () async {
      final api = clientFor([], (_) => json(200, cert(status: 'revoked')));
      expect(
        () => CertificateApiService.ensure(stone(certNo: 'GE-202610-00001'),
            client: api),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('revoked'))),
      );
    });

    test('a withdrawn certificate cannot be exported either', () async {
      final api = clientFor([], (_) => json(200, cert(status: 'withdrawn')));
      expect(
        () => CertificateApiService.ensure(stone(certNo: 'GE-202610-00001'),
            client: api),
        throwsA(isA<ApiException>()),
      );
    });

    test('404 is an offline certificate (issued before this update)',
        () async {
      final sent = <http.Request>[];
      final api = clientFor(sent, (_) => json(404, {'detail': 'Not found.'}));
      final r = await CertificateApiService.ensure(
          stone(certNo: 'GE-202609-00007'),
          client: api);
      expect(sent.single.method, 'GET');
      expect(r.certificateNumber, 'GE-202609-00007');
      expect(r.certificateVerifyUrl, isNull);
      expect(r.certificateOwnerName, isNull);
    });

    test('a number that belongs to another stone stays offline', () async {
      final api = clientFor([], (_) => json(200, cert(grading: 'other')));
      final r = await CertificateApiService.ensure(
          stone(certNo: 'GE-202610-00001'),
          client: api);
      expect(r.certificateVerifyUrl, isNull);
    });

    test('PDF upload ignores an already uploaded PDF (409)', () async {
      final sent = <http.Request>[];
      final api = clientFor(sent,
          (_) => json(409, {'detail': 'The PDF has already been uploaded.'}));
      await CertificateApiService.uploadPdf(
          'GE-202610-00001', Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
          client: api);
      expect(sent.single.url.path, '/certificates/GE-202610-00001/pdf');
    });
  });

  test('history reads every page of /certificates for the badges', () async {
    final sent = <http.Request>[];
    final api = clientFor(sent, (req) {
      if (req.url.path == '/gradings') {
        return json(200, {
          'items': [gradingItem('g1'), gradingItem('g2')],
          'next_cursor': null,
        });
      }
      final second = req.url.queryParameters['cursor'] == 'c2';
      return json(200, {
        'items': [
          {
            'cert_no': second ? 'GE-202601-00001' : 'GE-202610-00002',
            'grading_id': second ? 'g2' : 'g1',
            'status': 'valid',
            'verify_url': 'https://v.test/v/${second ? 'old' : 'new'}',
          }
        ],
        'next_cursor': second ? null : 'c2',
      });
    });
    HistoryService.invalidateCertificates();
    final page = await HistoryService.fetchPage(client: api);
    expect(page.items[0].certificateNumber, 'GE-202610-00002');
    expect(page.items[1].certificateNumber, 'GE-202601-00001');
    expect(sent.where((q) => q.url.path == '/certificates'), hasLength(2));
  });

  group('dead session', () {
    tearDown(() => ApiClient.sessionLostHandler = null);

    test('account_deleted calls the shared handler once', () async {
      final seen = <ApiErrorCode>[];
      ApiClient.sessionLostHandler = (e) async => seen.add(e.code);
      final api = clientFor(
          [],
          (_) => json(401,
              {'status': 'error', 'code': 'account_deleted', 'message': 'x'}));
      await expectLater(api.getJson('/me'), throwsA(isA<ApiException>()));
      expect(seen, [ApiErrorCode.accountDeleted]);
    });

    test('401 after the token refresh calls the handler', () async {
      final seen = <ApiErrorCode>[];
      ApiClient.sessionLostHandler = (e) async => seen.add(e.code);
      final api = clientFor([], (_) => json(401, {'detail': 'no'}));
      await expectLater(api.getJson('/me'), throwsA(isA<ApiException>()));
      expect(seen, [ApiErrorCode.unauthorized]);
    });

    test('other errors and guardSession false do not', () async {
      final seen = <ApiErrorCode>[];
      ApiClient.sessionLostHandler = (e) async => seen.add(e.code);
      await expectLater(
          clientFor([], (_) => json(404, {'detail': 'x'})).getJson('/x'),
          throwsA(isA<ApiException>()));
      await expectLater(
          clientFor([], (_) => json(401, {'code': 'reauth_required'}))
              .delete('/me', guardSession: false),
          throwsA(isA<ApiException>()));
      expect(seen, isEmpty);
    });
  });

  group('pending calibrations', () {
    CalibrationSession session(String id) => CalibrationSession(
          id: id,
          createdAt: DateTime.utc(2026, 10, 5),
          validUntil: DateTime.utc(2026, 10, 5, 8),
          deviceModel: 'Pixel',
          ccm: [1, 0, 0, 0, 1, 0, 0, 0, 1],
          residual: 0.2,
          quality: CalibrationQuality.excellent,
          measured: List.generate(6, (_) => [1.0, 2.0, 3.0]),
          perPatchError: List.filled(6, 0.1),
        );

    Future<List<String>> pending() async {
      final raw = await const FlutterSecureStorage()
          .read(key: 'calibration_pending_ids');
      return raw == null ? [] : (jsonDecode(raw) as List).cast<String>();
    }

    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('network and 5xx failures are kept once, without duplicates',
        () async {
      final s = session('S-1');
      final api = clientFor([], (_) => json(503, {'detail': 'x'}));
      expect(await CalibrationService.syncToServer(s, client: api), false);
      expect(await CalibrationService.syncToServer(s, client: api), false);
      expect(await pending(), ['S-1']);
    });

    test('a 4xx drops the session from the list', () async {
      final s = session('S-2');
      await CalibrationService.syncToServer(s,
          client: clientFor([], (_) => json(503, {'detail': 'x'})));
      expect(await pending(), ['S-2']);
      final ok = await CalibrationService.syncToServer(s,
          client: clientFor([], (_) => json(400, {'detail': 'bad'})));
      expect(ok, false);
      expect(await pending(), isEmpty);
    });

    test('409 counts as sent', () async {
      final s = session('S-3');
      await CalibrationService.syncToServer(s,
          client: clientFor([], (_) => json(503, {'detail': 'x'})));
      final ok = await CalibrationService.syncToServer(s,
          client: clientFor(
              [], (_) => json(409, {'code': 'duplicate_session'})));
      expect(ok, true);
      expect(await pending(), isEmpty);
    });

    test('two offline sessions are both kept', () async {
      final down = clientFor([], (_) => json(503, {'detail': 'x'}));
      await CalibrationService.syncToServer(session('S-4'), client: down);
      await CalibrationService.syncToServer(session('S-5'), client: down);
      expect(await pending(), ['S-4', 'S-5']);
    });
  });

  group('profile settings', () {
    test('PUT /me sends the threshold as a fraction', () async {
      final sent = <http.Request>[];
      final api = clientFor(sent, (_) => json(200, {}));
      await MeService.updateSettings(
          referralThresholdPercent: 65, showNameOnCertificates: true, client: api);
      expect(sent.single.method, 'PUT');
      expect(jsonDecode(sent.single.body), {
        'settings': {'referral_threshold': 0.65, 'show_name_on_certificates': true}
      });
    });

    test('GET /me settings are applied locally', () async {
      await MeService.apply({
        'settings': {'referral_threshold': 0.7, 'show_name_on_certificates': true}
      });
      expect(SettingsService.referralThreshold.value, 70);
      expect(SettingsService.showNameOnCertificates.value, true);
    });

    test('DELETE /me', () async {
      final sent = <http.Request>[];
      final api = clientFor(sent, (_) => http.Response('', 204));
      await MeService.deleteAccount(client: api);
      expect(sent.single.method, 'DELETE');
      expect(sent.single.url.path, '/me');
    });

    test('reauth_required is reported as such', () async {
      final api = clientFor(
          [],
          (_) => json(401, {
                'status': 'error',
                'code': 'reauth_required',
                'message': 'Please sign in again to delete your account.',
              }));
      expect(
        () => MeService.deleteAccount(client: api),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.reauthRequired)),
      );
    });
  });

  group('remote config', () {
    test('versions compare numerically', () {
      expect(RemoteConfigService.compareVersions('1.0', '1.0.0'), 0);
      expect(RemoteConfigService.compareVersions('1.9', '1.10'), -1);
      expect(RemoteConfigService.compareVersions('2.0.1', '2.0'), 1);
    });

    test('feature switches, maintenance and min version are applied', () {
      RemoteConfigService.apply({
        'min_app_version': '9.0.0',
        'maintenance': {'enabled': true, 'message': 'Back soon'},
        'features': {'repeatability_mode': false, 'gradcam': true},
      });
      expect(RemoteConfigService.repeatabilityEnabled, false);
      expect(RemoteConfigService.gradcamEnabled, true);
      expect(RemoteConfigService.maintenance, true);
      expect(RemoteConfigService.maintenanceMessage, 'Back soon');
      expect(RemoteConfigService.updateRequired, true);
      RemoteConfigService.apply({'min_app_version': '1.0.0'});
      expect(RemoteConfigService.updateRequired, false);
      expect(RemoteConfigService.repeatabilityEnabled, true);
    });
  });
}
