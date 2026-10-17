import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';
import 'notification_service.dart';

/// Active admin announcements (from `GET /config`): the dismissible Home
/// banner and one entry in the notification list per announcement.
/// Dismissed and already-notified ids are kept on this device
/// (SharedPreferences; not sensitive).
class AnnouncementService {
  AnnouncementService._();

  static const String _dismissedKey = 'announcements_dismissed';
  static const String _notifiedKey = 'announcements_notified';

  /// Kept ids per list, so the stored lists stay small.
  static const int _maxIds = 200;

  /// Active announcements from the last /config, newest config wins.
  static final ValueNotifier<List<Announcement>> active =
      ValueNotifier<List<Announcement>>(const []);

  /// Active announcements the user has not dismissed (Home banner).
  static final ValueNotifier<List<Announcement>> visible =
      ValueNotifier<List<Announcement>>(const []);

  static Set<String>? _dismissed;
  static Future<void>? _notifying;

  /// Called by RemoteConfigService.apply with the `announcements` field.
  static void setActive(Object? json) {
    active.value = Announcement.listFromJson(json);
    _publish();
    unawaited(_loadDismissed().then((_) => _publish()));
  }

  static void _publish() {
    final dismissed = _dismissed ?? const <String>{};
    visible.value =
        active.value.where((a) => !dismissed.contains(a.id)).toList();
  }

  /// Hides the banner for good on this device.
  static Future<void> dismiss(String id) async {
    final dismissed = await _loadDismissed();
    dismissed.add(id);
    _publish();
    await _saveIds(_dismissedKey, dismissed);
  }

  /// Adds every active announcement to the notification list once per
  /// account [uid] (also after it was dismissed or cleared). Concurrent calls
  /// share one run.
  static Future<void> notifyNew(String uid) =>
      _notifying ??= _notifyNew(uid).whenComplete(() => _notifying = null);

  static Future<void> _notifyNew(String uid) async {
    try {
      final items = active.value;
      if (items.isEmpty) return;
      final key = '${_notifiedKey}_$uid';
      final notified = await _readIds(key);
      var changed = false;
      for (final a in items) {
        if (notified.contains(a.id)) continue;
        await NotificationService.add(
          id: a.notificationId,
          type: a.notificationType,
          title: a.title,
          message: a.message,
          action: a.action,
        );
        notified.add(a.id);
        changed = true;
      }
      if (changed) await _saveIds(key, notified);
    } catch (e) {
      if (kDebugMode) debugPrint('Announcement notifications failed: $e');
    }
  }

  /// Drops the in-memory state (tests, sign-out). Stored ids are kept.
  @visibleForTesting
  static void reset() {
    _dismissed = null;
    active.value = const [];
    visible.value = const [];
  }

  static Future<Set<String>> _loadDismissed() async =>
      _dismissed ??= await _readIds(_dismissedKey);

  static Future<Set<String>> _readIds(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(key) ?? const []).toSet();
    } catch (e) {
      if (kDebugMode) debugPrint('Announcement ids not read: $e');
      return <String>{};
    }
  }

  static Future<void> _saveIds(String key, Set<String> ids) async {
    try {
      final list = ids.toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          key, list.length > _maxIds ? list.sublist(list.length - _maxIds) : list);
    } catch (e) {
      if (kDebugMode) debugPrint('Announcement ids not saved: $e');
    }
  }
}
