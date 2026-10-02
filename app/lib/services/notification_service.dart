import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_notification.dart';

// Local in-app notification store (SharedPreferences, newest first, max 100).
//
// Planned events not wired yet:
// TODO(backend): error "Grading failed" when the grading request fails
//   (action openCapture).
// TODO: info "Privacy policy updated" when the policy version changes
//   (action openPrivacy).
class NotificationService {
  static const String _storageKey = 'app_notifications';
  static const int maxItems = 100;

  /// Live unread count for the bell badge.
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Loads the stored list once so [unreadCount] is correct at startup.
  static Future<void> init() async {
    await list();
  }

  static Future<List<AppNotification>> list() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey) ?? [];
      final items = raw
          .map((s) =>
              AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      unreadCount.value = items.where((n) => !n.read).length;
      return items;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService.list failed: $e');
      return [];
    }
  }

  static Future<void> _save(List<AppNotification> items) async {
    try {
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final trimmed = items.take(maxItems).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _storageKey,
        trimmed.map((n) => jsonEncode(n.toJson())).toList(),
      );
      unreadCount.value = trimmed.where((n) => !n.read).length;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService.save failed: $e');
    }
  }

  static Future<void> add({
    required AppNotificationType type,
    required String title,
    required String message,
    AppNotificationAction action = AppNotificationAction.none,
    String? payload,
  }) async {
    final items = await list();
    items.insert(
      0,
      AppNotification(
        id: const Uuid().v4(),
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        action: action,
        payload: payload,
      ),
    );
    await _save(items);
  }

  static Future<void> markRead(String id) async {
    final items = await list();
    final i = items.indexWhere((n) => n.id == id);
    if (i < 0 || items[i].read) return;
    items[i] = items[i].copyWith(read: true);
    await _save(items);
  }

  static Future<void> markAllRead() async {
    final items = await list();
    await _save(items.map((n) => n.copyWith(read: true)).toList());
  }

  static Future<void> delete(String id) async {
    final items = await list();
    items.removeWhere((n) => n.id == id);
    await _save(items);
  }

  static Future<void> clearAll() async {
    await _save([]);
  }
}
