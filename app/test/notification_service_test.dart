import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemeye/models/app_notification.dart';
import 'package:gemeye/services/api_client.dart';
import 'package:gemeye/services/notification_service.dart';
import 'package:gemeye/services/settings_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<http.Request> calls;
  late bool online;
  List<Map<String, dynamic>> serverItems = [];

  ApiClient fakeServer() => ApiClient(
        baseUrl: 'https://api.test',
        tokenProvider: (_) async => 't',
        client: MockClient((req) async {
          if (!online) throw const SocketException('offline');
          calls.add(req);
          if (req.method == 'GET') {
            return http.Response(
                jsonEncode({'items': serverItems, 'unread_count': 0}), 200);
          }
          if (req.url.path.endsWith('/sync')) {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            return http.Response(
                jsonEncode({
                  'accepted': [
                    for (final i in body['items'] as List) (i as Map)['id']
                  ]
                }),
                200);
          }
          if (req.url.path.contains('/gone-')) {
            return http.Response(jsonEncode({'detail': 'Not found.'}), 404);
          }
          return http.Response('{}', 200);
        }),
      );

  Map<String, dynamic> server(String id, {String? category, bool read = false}) =>
      {
        'id': id,
        'type': 'info',
        'category': category,
        'title': 'T $id',
        'message': 'M',
        'action': 'none',
        'payload': null,
        'source': 'server',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'read': read,
      };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    online = true;
    serverItems = [];
    NotificationService.client = fakeServer();
    NotificationService.signedIn = () => true;
    for (final c in NotificationCategory.values) {
      SettingsService.notifierFor(c).value = true;
    }
  });

  tearDown(() {
    NotificationService.client = null;
    NotificationService.signedIn = null;
  });

  group('pending queue', () {
    test('offline changes are queued in order and sent when back online',
        () async {
      online = false;
      await NotificationService.add(
          type: AppNotificationType.info, title: 'A', message: 'a');
      await NotificationService.add(
          type: AppNotificationType.info, title: 'B', message: 'b');
      await NotificationService.flush();
      final ops = await NotificationService.pending();
      expect(ops.map((o) => o['op']), ['add', 'add']);
      final first = (ops.first['item'] as Map)['id'] as String;
      await NotificationService.markRead(first);
      await NotificationService.clear(first);
      await NotificationService.flush();
      expect((await NotificationService.pending()).map((o) => o['op']),
          ['add', 'add', 'read', 'clear']);
      expect(calls, isEmpty);

      online = true;
      await NotificationService.flush();
      expect(await NotificationService.pending(), isEmpty);
      // Both adds go in one sync batch, then read, then clear.
      expect(calls.map((r) => r.url.path).toList(), [
        '/me/notifications/sync',
        '/me/notifications/$first/read',
        '/me/notifications/$first/clear',
      ]);
      final sent = jsonDecode(calls.first.body)['items'] as List;
      expect(sent.map((i) => i['title']), ['A', 'B']);
    });

    test('a 4xx drops the operation, a network failure keeps it', () async {
      await NotificationService.clear('gone-1');
      await NotificationService.flush();
      expect(await NotificationService.pending(), isEmpty);

      online = false;
      await NotificationService.clearAll();
      await NotificationService.flush();
      final ops = await NotificationService.pending();
      expect(ops.single['op'], 'clearAll');
      expect(ops.single['before'], isNotNull);
      online = true;
      await NotificationService.flush();
      expect(calls.last.url.path, '/me/notifications/clear-all');
      expect(calls.last.url.queryParameters['before'], ops.single['before']);
    });

    test('list() uses the cache offline and the server list online',
        () async {
      serverItems = [server('s1'), server('s2')];
      expect((await NotificationService.list()).length, 2);
      await NotificationService.clear('s1');
      await NotificationService.flush();
      online = false;
      expect((await NotificationService.list()).map((n) => n.id), ['s2']);

      // An admin restore: the server returns s1 again, so it shows again.
      online = true;
      expect((await NotificationService.list()).map((n) => n.id).toSet(),
          {'s1', 's2'});
    });

    test('merge applies pending clears and adds', () {
      final local = AppNotification(
          id: 'l1',
          type: AppNotificationType.info,
          title: 'L',
          message: 'm',
          createdAt: DateTime.now());
      final merged = NotificationService.merge(
        [
          AppNotification.fromServerJson(server('s1')),
          AppNotification.fromServerJson(server('s2')),
        ],
        [
          {'op': 'add', 'item': local.toJson()},
          {'op': 'clear', 'id': 's1'},
          {'op': 'read', 'id': 's2'},
        ],
      );
      expect(merged.map((n) => n.id).toSet(), {'l1', 's2'});
      expect(merged.firstWhere((n) => n.id == 's2').read, isTrue);
    });

    test('signed out: local only, nothing queued', () async {
      NotificationService.signedIn = () => false;
      await NotificationService.add(
          type: AppNotificationType.info, title: 'A', message: 'a');
      expect(await NotificationService.pending(), isEmpty);
      expect((await NotificationService.list()).single.title, 'A');
      expect(calls, isEmpty);
    });
  });

  group('categories', () {
    test('switched-off categories are recorded but hidden', () async {
      NotificationService.signedIn = () => false;
      SettingsService.notifierFor(NotificationCategory.referral).value = false;
      await NotificationService.add(
          type: AppNotificationType.warning,
          title: 'Referral',
          message: 'r',
          category: NotificationCategory.referral);
      await NotificationService.add(
          type: AppNotificationType.info, title: 'Plain', message: 'p');

      final shown = await NotificationService.list();
      expect(shown.map((n) => n.title), ['Plain']);
      expect(NotificationService.unreadCount.value, 1);

      SettingsService.notifierFor(NotificationCategory.referral).value = true;
      final all = await NotificationService.list();
      expect(all.map((n) => n.title).toSet(), {'Referral', 'Plain'});
      expect(all.firstWhere((n) => n.title == 'Referral').category,
          NotificationCategory.referral);
      expect(NotificationService.unreadCount.value, 2);
    });

    test('server items of a hidden category are hidden too', () async {
      SettingsService.notifierFor(NotificationCategory.certificate).value =
          false;
      serverItems = [
        server('c1', category: 'certificate'),
        server('n1'),
      ];
      final shown = await NotificationService.list();
      expect(shown.map((n) => n.id), ['n1']);
    });
  });
}
