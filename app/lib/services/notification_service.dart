import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_notification.dart';
import 'api_client.dart';
import 'connectivity_service.dart';
import 'settings_service.dart';

// In-app notifications. Signed in, the server is the source of truth: list()
// loads GET /me/notifications and keeps a local cache (SharedPreferences,
// newest first, max 100) for offline use. add, markRead, markAllRead, clear
// and clearAll change the cache at once and queue the server call; the queue
// is sent in order and retried on app start, app resume and when the network
// comes back. Cleared notifications are never deleted on the server, and an
// admin restore brings them back through the next list(). Signed out, the
// cache is the only store.
//
// Every notification is recorded with its category; categories switched off
// in Settings are only hidden from the list and the bell badge.
//
// Planned events not wired yet:
// TODO: info "Privacy policy updated" when the policy version changes
//   (action openPrivacy).
class NotificationService {
  static const String _storageKey = 'app_notifications';
  static const String _pendingKey = 'app_notifications_pending';
  static const int maxItems = 100;
  static const int syncBatch = 50;

  /// Live unread count for the bell badge (switched-off categories excluded).
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Test hooks: the API client and the signed-in check.
  @visibleForTesting
  static ApiClient? client;
  @visibleForTesting
  static bool Function()? signedIn;

  static ApiClient get _api => client ?? ApiClient.instance;
  static bool get _isSignedIn =>
      signedIn?.call() ?? FirebaseAuth.instance.currentUser != null;

  static Future<void>? _flushing;
  static _ResumeObserver? _observer;

  /// Loads the cache so [unreadCount] is correct at startup, sends anything
  /// queued and registers the resume and connectivity retries.
  static Future<void> init() async {
    _publish(await _cached());
    if (_observer == null) {
      _observer = _ResumeObserver();
      WidgetsBinding.instance.addObserver(_observer!);
      ConnectivityService.online.addListener(() {
        if (ConnectivityService.online.value) unawaited(flush());
      });
    }
    unawaited(flush());
  }

  /// Visible notifications, newest first. Signed in, refreshed from the
  /// server (the cache is used when it cannot be reached).
  static Future<List<AppNotification>> list() async {
    var items = await _cached();
    if (_isSignedIn) {
      await flush();
      try {
        final json = await _api
            .getJson('/me/notifications', query: {'limit': '$maxItems'});
        final server = (json['items'] as List? ?? const [])
            .map((e) =>
                AppNotification.fromServerJson(e as Map<String, dynamic>))
            .toList();
        items = merge(server, await _pending());
        await _store(items);
      } catch (e) {
        if (kDebugMode) debugPrint('Notifications not loaded: $e');
      }
    }
    _publish(items);
    return visible(items);
  }

  /// Server list plus the changes still in the queue (not yet sent, so the
  /// server does not reflect them).
  @visibleForTesting
  static List<AppNotification> merge(
      List<AppNotification> server, List<Map<String, dynamic>> pending) {
    final byId = {for (final n in server) n.id: n};
    for (final op in pending) {
      final id = op['id'] as String?;
      final before = op['before'] == null
          ? null
          : DateTime.parse(op['before'] as String);
      switch (op['op']) {
        case 'add':
          final n = AppNotification.fromJson(
              (op['item'] as Map).cast<String, dynamic>());
          byId.putIfAbsent(n.id, () => n);
        case 'read':
          final n = byId[id];
          if (n != null) byId[id!] = n.copyWith(read: true);
        case 'readAll':
          byId.updateAll((_, n) =>
              before == null || !n.createdAt.isAfter(before)
                  ? n.copyWith(read: true)
                  : n);
        case 'clear':
          byId.remove(id);
        case 'clearAll':
          byId.removeWhere(
              (_, n) => before == null || !n.createdAt.isAfter(before));
      }
    }
    return _sorted(byId.values.toList());
  }

  /// Hides categories switched off in Settings.
  @visibleForTesting
  static List<AppNotification> visible(List<AppNotification> items) => items
      .where((n) => n.category == null || SettingsService.isEnabled(n.category!))
      .toList();

  static Future<void> add({
    required AppNotificationType type,
    required String title,
    required String message,
    AppNotificationAction action = AppNotificationAction.none,
    String? payload,
    NotificationCategory? category,
  }) async {
    final n = AppNotification(
      id: const Uuid().v4(),
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      action: action,
      payload: payload,
      category: category,
    );
    await _save((await _cached())..insert(0, n));
    await _queue({'op': 'add', 'item': n.toJson()});
  }

  static Future<void> markRead(String id) async {
    final items = await _cached();
    final i = items.indexWhere((n) => n.id == id);
    if (i < 0 || items[i].read) return;
    items[i] = items[i].copyWith(read: true);
    await _save(items);
    await _queue({'op': 'read', 'id': id});
  }

  static Future<void> markAllRead() async {
    final items = await _cached();
    await _save(items.map((n) => n.copyWith(read: true)).toList());
    await _queue({'op': 'readAll', 'before': _now()});
  }

  /// Hides one notification for good (the server keeps it, cleared).
  static Future<void> clear(String id) async {
    await _save((await _cached())..removeWhere((n) => n.id == id));
    await _queue({'op': 'clear', 'id': id});
  }

  /// Hides every notification received so far.
  static Future<void> clearAll() async {
    await _save([]);
    await _queue({'op': 'clearAll', 'before': _now()});
  }

  /// Drops the cache and the queue on this device only (sign-out, account
  /// deletion). Nothing is sent to the server.
  static Future<void> wipeLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_pendingKey);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService.wipeLocal failed: $e');
    }
    unreadCount.value = 0;
  }

  // ---- Pending queue ----

  static String _now() => DateTime.now().toUtc().toIso8601String();

  static Future<void> _queue(Map<String, dynamic> op) async {
    if (!_isSignedIn) return;
    await _setPending((await _pending())..add(op));
    unawaited(flush());
  }

  /// Sends the queue in order. Stops at the first network or server failure
  /// (the rest is retried later); an operation refused with a 4xx is dropped.
  static Future<void> flush() {
    if (!_isSignedIn) return Future.value();
    return _flushing ??= _flush().whenComplete(() => _flushing = null);
  }

  static Future<void> _flush() async {
    while (true) {
      final ops = await _pending();
      if (ops.isEmpty) return;
      final op = ops.first;
      var take = 1;
      try {
        switch (op['op']) {
          case 'add':
            final batch = ops
                .takeWhile((o) => o['op'] == 'add')
                .take(syncBatch)
                .toList();
            take = batch.length;
            await _api.postJson('/me/notifications/sync', {
              'items': [
                for (final o in batch)
                  AppNotification.fromJson(
                          (o['item'] as Map).cast<String, dynamic>())
                      .toServerJson(),
              ],
            });
          case 'read':
            await _api.postJson(
                '/me/notifications/${Uri.encodeComponent(op['id'] as String)}/read',
                null);
          case 'clear':
            await _api.postJson(
                '/me/notifications/${Uri.encodeComponent(op['id'] as String)}/clear',
                null);
          case 'readAll':
          case 'clearAll':
            final path = op['op'] == 'readAll' ? 'read-all' : 'clear-all';
            final before = Uri.encodeQueryComponent(op['before'] as String);
            await _api.postJson('/me/notifications/$path?before=$before', null);
        }
      } on ApiException catch (e) {
        if (_retryable(e)) return;
        if (kDebugMode) debugPrint('Notification ${op['op']} dropped: $e');
      } catch (e) {
        if (kDebugMode) debugPrint('Notification sync failed: $e');
        return;
      }
      // Re-read: new operations may have been queued meanwhile (appended).
      final now = await _pending();
      await _setPending(now.length > take ? now.sublist(take) : []);
    }
  }

  static bool _retryable(ApiException e) => switch (e.code) {
        ApiErrorCode.offline ||
        ApiErrorCode.timeout ||
        ApiErrorCode.serverError ||
        ApiErrorCode.maintenance ||
        ApiErrorCode.unauthorized ||
        ApiErrorCode.reauthRequired =>
          true,
        _ => false,
      };

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> pending() => _pending();

  static Future<List<Map<String, dynamic>>> _pending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_pendingKey) ?? [])
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Notification queue not read: $e');
      return [];
    }
  }

  static Future<void> _setPending(List<Map<String, dynamic>> ops) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_pendingKey, ops.map(jsonEncode).toList());
    } catch (e) {
      if (kDebugMode) debugPrint('Notification queue not saved: $e');
    }
  }

  // ---- Local cache ----

  static List<AppNotification> _sorted(List<AppNotification> items) =>
      items..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  static Future<List<AppNotification>> _cached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey) ?? [];
      return _sorted(raw
          .map((s) =>
              AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList());
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService.list failed: $e');
      return [];
    }
  }

  static Future<void> _store(List<AppNotification> items) async {
    try {
      final trimmed = _sorted(items).take(maxItems).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _storageKey,
        trimmed.map((n) => jsonEncode(n.toJson())).toList(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService.save failed: $e');
    }
  }

  static Future<void> _save(List<AppNotification> items) async {
    await _store(items);
    _publish(items);
  }

  static void _publish(List<AppNotification> items) {
    unreadCount.value = visible(items).where((n) => !n.read).length;
  }
}

class _ResumeObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(NotificationService.flush());
    }
  }
}
