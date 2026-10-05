import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gemeye/services/api_client.dart';
import 'package:gemeye/services/heatmap_service.dart';
import 'package:gemeye/widgets/gradcam_card.dart';

/// 1x1 transparent PNG.
final Uint8List png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

HeatmapImage heatmap() => HeatmapImage(
    bytes: png, method: 'gradcam_cnn_branch', targetGrade: 4,
    stoneHeatFraction: 0.8);

Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)));

http.Response json(int status, Object body) => http.Response(
    jsonEncode(body), status,
    headers: {'content-type': 'application/json'});

void main() {
  group('GradCamCard', () {
    testWidgets('spinner while loading, then the image', (tester) async {
      final done = Completer<HeatmapImage>();
      final calls = <String>[];
      await tester.pumpWidget(host(GradCamCard(
          gradingId: 'g1',
          enabled: true,
          loader: (id) {
            calls.add(id);
            return done.future;
          })));
      expect(find.byKey(const Key('gradcam_loading')), findsOneWidget);
      expect(find.byKey(const Key('gradcam_image')), findsNothing);
      expect(find.text(GradCamCard.legend), findsOneWidget);
      expect(find.text(GradCamCard.explanation), findsOneWidget);
      done.complete(heatmap());
      await tester.pump();
      expect(find.byKey(const Key('gradcam_loading')), findsNothing);
      expect(find.byKey(const Key('gradcam_image')), findsOneWidget);
      expect(calls, ['g1']);
    });

    testWidgets('error state with retry', (tester) async {
      var n = 0;
      await tester.pumpWidget(host(GradCamCard(
          gradingId: 'g1',
          enabled: true,
          loader: (_) async {
            n++;
            if (n == 1) {
              throw const ApiException(ApiErrorCode.offline,
                  'No internet connection. Check your connection and try again.');
            }
            return heatmap();
          })));
      await tester.pump();
      expect(find.byKey(const Key('gradcam_error')), findsOneWidget);
      expect(find.text('No internet connection. Check your connection and try again.'),
          findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(n, 2);
      expect(find.byKey(const Key('gradcam_error')), findsNothing);
      expect(find.byKey(const Key('gradcam_image')), findsOneWidget);
    });

    testWidgets('maintenance and not-found messages', (tester) async {
      await tester.pumpWidget(host(GradCamCard(
          gradingId: 'g1',
          enabled: true,
          loader: (_) async => throw const ApiException(
              ApiErrorCode.maintenance, 'Back at 10:00', statusCode: 503))));
      await tester.pump();
      expect(find.text('Back at 10:00'), findsOneWidget);

      await tester.pumpWidget(host(GradCamCard(
          gradingId: 'g2',
          enabled: true,
          loader: (_) async => throw const ApiException(
              ApiErrorCode.notFound, 'Not found.', statusCode: 404))));
      await tester.pump();
      expect(find.text(GradCamCard.unavailable), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('disabled: hidden and never calls the server', (tester) async {
      var n = 0;
      await tester.pumpWidget(host(GradCamCard(
          gradingId: 'g1',
          enabled: false,
          loader: (_) async {
            n++;
            return heatmap();
          })));
      await tester.pump();
      expect(n, 0);
      expect(find.text('GRAD-CAM HEATMAP'), findsNothing);
      expect(find.text(GradCamCard.legend), findsNothing);
    });

    testWidgets('no server grading id: not available, no call', (tester) async {
      var n = 0;
      await tester.pumpWidget(host(GradCamCard(
          gradingId: null,
          enabled: true,
          loader: (_) async {
            n++;
            return heatmap();
          })));
      await tester.pump();
      expect(n, 0);
      expect(find.text(GradCamCard.unavailable), findsOneWidget);
    });

    test('user-visible text has no em or en dashes', () {
      for (final s in [GradCamCard.legend, GradCamCard.explanation,
          GradCamCard.unavailable]) {
        expect(s.contains('—') || s.contains('–'), isFalse);
      }
    });
  });

  group('HeatmapService', () {
    setUp(HeatmapService.clearCache);
    tearDown(() => ApiClient.sessionLostHandler = null);

    ApiClient api(List<http.Request> sent,
            http.Response Function(http.Request) handler) =>
        ApiClient(
          baseUrl: 'http://api.test',
          tokenProvider: (_) async => 't',
          client: MockClient((req) async {
            sent.add(req);
            return handler(req);
          }),
        );

    test('posts, downloads the presigned PNG and caches it', () async {
      final sent = <http.Request>[];
      final c = api(sent, (_) => json(200, {
            'url': 'http://s3.test/cam.png',
            'method': 'gradcam_cnn_branch',
            'target_grade': 4,
            'stone_mask_heat_fraction': 0.82,
          }));
      final downloads = <Uri>[];
      final dl = MockClient((req) async {
        downloads.add(req.url);
        return http.Response.bytes(png, 200);
      });
      final h = await HeatmapService.fetch('g1', client: c, download: dl);
      expect(sent.single.method, 'POST');
      expect(sent.single.url.path, '/gradings/g1/heatmap');
      expect(sent.single.headers['Authorization'], 'Bearer t');
      expect(downloads.single.toString(), 'http://s3.test/cam.png');
      expect(h.bytes, png);
      expect(h.targetGrade, 4);
      expect(h.stoneHeatFraction, 0.82);
      await HeatmapService.fetch('g1', client: c, download: dl);
      expect(sent.length, 1);
      expect(downloads.length, 1);
    });

    test('maintenance and session-lost errors', () async {
      final c1 = api([], (_) => json(503, {
            'status': 'error', 'code': 'maintenance',
            'message': 'Back at 10:00', 'detail': 'Back at 10:00'}));
      await expectLater(
          HeatmapService.fetch('g1', client: c1),
          throwsA(isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.maintenance)
              .having((e) => e.message, 'message', 'Back at 10:00')));

      final lost = <ApiException>[];
      ApiClient.sessionLostHandler = (e) async => lost.add(e);
      final c2 = api([], (_) => json(401, {
            'status': 'error', 'code': 'account_deleted',
            'message': 'deleted', 'detail': 'deleted'}));
      await expectLater(HeatmapService.fetch('g1', client: c2),
          throwsA(isA<ApiException>()));
      expect(lost.single.code, ApiErrorCode.accountDeleted);
    });

    test('offline download gives the offline message', () async {
      final c = api([], (_) => json(200, {'url': 'http://s3.test/cam.png'}));
      final dl = MockClient(
          (_) async => throw http.ClientException('no network'));
      await expectLater(
          HeatmapService.fetch('g1', client: c, download: dl),
          throwsA(isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.offline)));
    });
  });
}
