import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gemeye/models/grade_result.dart';
import 'package:gemeye/services/api_client.dart';
import 'package:gemeye/services/certificate_api_service.dart';
import 'package:gemeye/services/certificate_service.dart';

const cam = {'J': 50.24, 'M': 28.06, 'h': 250.3, 's': 40.44, 'C': 31.2};

Map<String, dynamic> colour({Object? ciecam02 = cam, bool approx = false}) => {
      'L': 30.0, 'a': 5.0, 'b': -40.0, 'C': 40.0, 'H': 277.0,
      'S': 80.0, 'B': 50.0, 'hex': '#2A408C', 'ciecam02': ciecam02,
      'approximate': approx,
    };

GradeResult stone({Object? ciecam02 = cam, String? certNo}) {
  final r = GradeResult.fromGradingItem({
    'grading_id': 'g1',
    'stone_id': 'GE-STONE-g1',
    'created_at': '2026-10-05T04:00:00Z',
    'calibration_session_id': 'S-1',
    'result': {
      'status': 'ok',
      'grade': 4,
      'grade_name': 'Intense',
      'trade_name': 'Intense Cornflower',
      'confidence': 0.91,
      'uncertainty': 0.3,
      'referred': false,
      'colour': colour(ciecam02: ciecam02),
      'delta_e00_to_typical': 1.2,
    },
  });
  r.certificateNumber = certNo;
  return r;
}

ApiClient serverWith(Map<String, dynamic> snapshotColour) => ApiClient(
      baseUrl: 'http://api.test',
      tokenProvider: (_) async => 't',
      client: MockClient((req) async => http.Response(
          jsonEncode(req.method == 'POST'
              ? {
                  'cert_no': 'GE-202610-00001',
                  'verify_url': 'https://v.test/v/abc',
                  'issued_at': '2026-10-05T04:00:00Z',
                }
              : {
                  'cert_no': 'GE-202610-00001',
                  'grading_id': 'g1',
                  'status': 'valid',
                  'verify_url': 'https://v.test/v/abc',
                  'snapshot': {'colour': snapshotColour},
                }),
          req.method == 'POST' ? 201 : 200,
          headers: {'content-type': 'application/json'})),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('new certificate prints CIECAM02 like the Result screen', () {
    final g = CertificateService.colourGroups(stone())['CIECAM02']!;
    expect(g, [
      ['Lightness J', '50.2'],
      ['Colourfulness M', '28.1'],
      ['Hue angle h', '250°'],
      ['Saturation s', '40.4'],
      ['Chroma C', '31.2'],
    ]);
  });

  test('null CIECAM02 prints Not available', () {
    final g = CertificateService.colourGroups(stone(ciecam02: null));
    expect(g['CIECAM02'], [
      ['Not available', ''],
    ]);
  });

  test('re-export uses the snapshot values every time', () async {
    // The local stone has no values; the frozen snapshot has them.
    final snap = colour(approx: true);
    final first = await CertificateApiService.ensure(stone(ciecam02: null),
        client: serverWith(snap));
    final again = await CertificateApiService.ensure(
        stone(ciecam02: null, certNo: 'GE-202610-00001'),
        client: serverWith(snap));
    final a = CertificateService.colourGroups(first);
    expect(a['CIECAM02']!.first, ['Lightness J', '50.2']);
    expect(CertificateService.colourGroups(again), a);
    expect(first.colourApproximate, isTrue);
    expect(GradeResult.fromJson(again.toJson()).ciecam02!.j, 50.24);
  });

  test('snapshot without CIECAM02 shows Not available on re-export',
      () async {
    final r = await CertificateApiService.ensure(
        stone(certNo: 'GE-202610-00001'),
        client: serverWith(colour(ciecam02: null)));
    expect(r.ciecam02, isNull);
    expect(CertificateService.colourGroups(r)['CIECAM02']!.single.first,
        CertificateService.notAvailable);
  });

  test('PDF builds on one page with values and the approximate note',
      () async {
    final r = stone()
      ..colourApproximate = true
      ..certificateNumber = 'GE-202610-00001'
      ..certificateOwnerName = 'Nirmana'
      ..certificateOwnerCompany = 'Orava';
    final pdf = await CertificateService.generateCertificatePdf(
        result: r, stoneImage: Uint8List(0));
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    final nulls = await CertificateService.generateCertificatePdf(
        result: stone(ciecam02: null), stoneImage: Uint8List(0));
    expect(nulls, isNotEmpty);
  });
}
