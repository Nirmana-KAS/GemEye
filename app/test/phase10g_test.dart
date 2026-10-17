import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gemeye/models/announcement_model.dart';
import 'package:gemeye/models/app_notification.dart';
import 'package:gemeye/models/grade_result.dart';
import 'package:gemeye/screens/account_disabled_screen.dart';
import 'package:gemeye/screens/maintenance_screen.dart';
import 'package:gemeye/services/announcement_service.dart';
import 'package:gemeye/services/api_client.dart';
import 'package:gemeye/services/notification_service.dart';
import 'package:gemeye/services/remote_config_service.dart';
import 'package:gemeye/widgets/announcement_banner.dart';
import 'package:gemeye/widgets/reviewed_grade_badge.dart';
import 'phase5c_test.dart' show gradingItem;

/// Phase 10g: announcements, reviewed grade, disabled account, maintenance.

http.Response json(int status, Object body) => http.Response(
    jsonEncode(body), status,
    headers: {'content-type': 'application/json'});

Map<String, dynamic> ann(String id,
        {String level = 'info', String action = 'none'}) =>
    {
      'id': id,
      'title': 'Title $id',
      'message': 'Message $id',
      'level': level,
      'action': action,
      'starts_at': '2026-10-17T00:00:00Z',
      'ends_at': '2026-10-30T00:00:00Z',
    };

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnnouncementService.reset();
    NotificationService.client = null;
    NotificationService.signedIn = () => false;
  });
  tearDown(() {
    NotificationService.signedIn = null;
    RemoteConfigService.apply(const {});
  });

  group('announcements', () {
    test('parses /config announcements, levels and actions', () {
      final list = Announcement.listFromJson([
        ann('a1', level: 'warning', action: 'openCalibration'),
        ann('a2', action: 'somethingNew'),
        {'id': '', 'title': 'x', 'message': 'y'},
        'junk',
      ]);
      expect(list.map((a) => a.id), ['a1', 'a2']);
      expect(list[0].level, AnnouncementLevel.warning);
      expect(list[0].action, AppNotificationAction.openCalibration);
      expect(list[0].notificationType, AppNotificationType.warning);
      expect(list[1].level, AnnouncementLevel.info);
      expect(list[1].action, AppNotificationAction.none);
      expect(list[0].endsAt, DateTime.utc(2026, 10, 30));
      expect(Announcement.listFromJson(null), isEmpty);
      final id = list[0].notificationId;
      expect(id, 'ann-a100');
      expect(RegExp(r'^[A-Za-z0-9-]{8,64}$').hasMatch(id), isTrue);
    });

    test('RemoteConfigService.apply feeds the banner; dismissed ids are kept',
        () async {
      RemoteConfigService.apply({
        'announcements': [ann('a1'), ann('a2')]
      });
      await settle();
      expect(AnnouncementService.visible.value.map((a) => a.id), ['a1', 'a2']);
      await AnnouncementService.dismiss('a1');
      expect(AnnouncementService.visible.value.map((a) => a.id), ['a2']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('announcements_dismissed'), ['a1']);

      // A new launch (fresh memory) still hides it.
      AnnouncementService.reset();
      RemoteConfigService.apply({
        'announcements': [ann('a1'), ann('a2'), ann('a3')]
      });
      await settle();
      expect(AnnouncementService.visible.value.map((a) => a.id), ['a2', 'a3']);
      // Ended announcements drop out with the next /config.
      RemoteConfigService.apply({'announcements': []});
      expect(AnnouncementService.visible.value, isEmpty);
    });

    test('added to the notification list once per account', () async {
      RemoteConfigService.apply({
        'announcements': [ann('a1', level: 'warning', action: 'openHistory')]
      });
      await AnnouncementService.notifyNew('uid1');
      await AnnouncementService.notifyNew('uid1');
      var items = await NotificationService.list();
      expect(items.where((n) => n.id == 'ann-a100'), hasLength(1));
      final n = items.single;
      expect(n.title, 'Title a1');
      expect(n.type, AppNotificationType.warning);
      expect(n.action, AppNotificationAction.openHistory);

      // Cleared by the user: not added again.
      await NotificationService.clear(n.id);
      await AnnouncementService.notifyNew('uid1');
      expect(await NotificationService.list(), isEmpty);

      // Another account on this phone gets it once too.
      await AnnouncementService.notifyNew('uid2');
      items = await NotificationService.list();
      expect(items.map((n) => n.id), ['ann-a100']);
    });

    testWidgets('banner shows level, link and dismiss', (tester) async {
      var opened = 0, dismissed = 0;
      final a = Announcement.listFromJson(
          [ann('a1', level: 'warning', action: 'openCalibration')]).single;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnnouncementBanner(
            announcement: a,
            onAction: () => opened++,
            onDismiss: () => dismissed++,
          ),
        ),
      ));
      expect(find.text('Title a1'), findsOneWidget);
      expect(find.text('Message a1'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      await tester.tap(find.text('Calibrate'));
      await tester.tap(find.byTooltip('Dismiss'));
      expect((opened, dismissed), (1, 1));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnnouncementBanner(
              announcement: Announcement.listFromJson([ann('a2')]).single,
              onDismiss: () {}),
        ),
      ));
      expect(find.byIcon(Icons.campaign_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });
  });

  group('reviewed grade', () {
    test('GET /gradings review becomes the reviewed grade', () {
      final r = GradeResult.fromGradingItem({
        ...gradingItem('g1', referred: true),
        'review': {
          'gemologist_grade': 3,
          'reviewed_at': '2026-10-16T10:00:00Z',
          'notes': ' Slightly darker in daylight ',
        },
      });
      expect(r.reviewGrade, 3);
      expect(r.reviewNotes, 'Slightly darker in daylight');
      final back = GradeResult.fromJson(
          jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>);
      expect((back.reviewGrade, back.reviewNotes),
          (3, 'Slightly darker in daylight'));
      expect(r.withStoneId('GE-STONE-X').reviewGrade, 3);
    });

    test('no review, an unusable review and bad grades are not shown', () {
      expect(GradeResult.fromGradingItem(gradingItem('g2')).reviewGrade, isNull);
      for (final review in [
        null,
        {'gemologist_grade': null, 'reviewed_at': '2026-10-16T10:00:00Z'},
        {'gemologist_grade': 3, 'unusable': true},
        {'gemologist_grade': 8},
        {'gemologist_grade': '3'},
      ]) {
        expect(GradeResult.parseReview(review), isNull, reason: '$review');
      }
      // Older cached results without the fields still load.
      final old = GradeResult.fromGradingItem(gradingItem('g3')).toJson()
        ..remove('reviewGrade')
        ..remove('reviewNotes');
      expect(GradeResult.fromJson(old).reviewGrade, isNull);
    });

    testWidgets('badge text (history line and result card with notes)',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Column(children: [
            ReviewedGradeBadge(grade: 5, compact: true),
            ReviewedGradeBadge(grade: 2, notes: 'Checked under D65'),
          ]),
        ),
      ));
      expect(find.text('Reviewed by gemologist: Grade 5'), findsOneWidget);
      expect(find.text('Reviewed by gemologist: Grade 2'), findsOneWidget);
      expect(find.text('Checked under D65'), findsOneWidget);
    });
  });

  group('disabled account', () {
    final lost = <ApiException>[];
    setUp(() {
      lost.clear();
      ApiClient.sessionLostHandler = (e) async => lost.add(e);
    });
    tearDown(() => ApiClient.sessionLostHandler = null);

    ApiClient clientFor(List<http.Request> sent, http.Response response) =>
        ApiClient(
          baseUrl: 'http://api.test',
          tokenProvider: (_) async => 'token',
          client: MockClient((req) async {
            sent.add(req);
            return response;
          }),
        );

    for (final (status, code) in [
      (401, 'account_disabled'),
      (403, 'ACCOUNT_DISABLED'),
    ]) {
      test('$status $code is accountDisabled, sent once, session handler once',
          () async {
        final sent = <http.Request>[];
        final api = clientFor(
            sent,
            json(status, {
              'status': 'error',
              'code': code,
              'message': 'This account has been disabled.',
            }));
        await expectLater(
            api.getJson('/me'),
            throwsA(isA<ApiException>()
                .having((e) => e.code, 'code', ApiErrorCode.accountDisabled)
                .having((e) => e.message, 'message',
                    'Account disabled. Contact support.')));
        // No token refresh and no GET retry: one request only.
        expect(sent, hasLength(1));
        await Future<void>.delayed(Duration.zero);
        expect(lost.single.code, ApiErrorCode.accountDisabled);
      });
    }

    testWidgets('full screen: message, support email, sign out, no back',
        (tester) async {
      var signedOut = 0;
      await tester.pumpWidget(MaterialApp(
        home: AccountDisabledScreen(onSignOut: () async => signedOut++),
      ));
      expect(find.text('Account disabled'), findsOneWidget);
      expect(find.text('Account disabled. Contact support.'), findsOneWidget);
      expect(find.text('Email support'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      await tester.tap(find.text('Sign out'));
      expect(signedOut, 1);
      final pop = tester.widget<PopScope>(find.byType(PopScope));
      expect(pop.canPop, isFalse);
      final uri = AccountDisabledScreen.supportUri();
      expect(uri.scheme, 'mailto');
      expect(uri.path, contains('@'));
    });
  });

  group('maintenance', () {
    testWidgets('covers the app with the admin message; Retry re-reads config',
        (tester) async {
      var retries = 0;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MaintenanceGate(
          child: child!,
          onRetry: () async {
            retries++;
            RemoteConfigService.apply({
              'maintenance': {'enabled': false, 'message': ''}
            });
          },
        ),
        home: const Scaffold(body: Text('Home screen')),
      ));
      expect(find.text('Home screen'), findsOneWidget);

      RemoteConfigService.apply({
        'maintenance': {'enabled': true, 'message': 'Back at 5 PM'}
      });
      await tester.pump();
      expect(find.text('Under maintenance'), findsOneWidget);
      expect(find.text('Back at 5 PM'), findsOneWidget);
      expect(find.text('Home screen'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(retries, 1);
      expect(find.text('Under maintenance'), findsNothing);
      expect(find.text('Home screen'), findsOneWidget);
    });

    testWidgets('empty message uses the default text', (tester) async {
      RemoteConfigService.apply({
        'maintenance': {'enabled': true, 'message': ' '}
      });
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) =>
            MaintenanceGate(child: child!, onRetry: () async {}),
        home: const SizedBox(),
      ));
      expect(find.text(MaintenanceScreen.defaultMessage), findsOneWidget);
    });
  });
}
