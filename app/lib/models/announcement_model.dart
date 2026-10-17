import 'app_notification.dart';

enum AnnouncementLevel { info, warning }

/// An admin announcement from `GET /config` (`announcements`): only the
/// active ones inside their time window are sent.
class Announcement {
  final String id;
  final String title;
  final String message;
  final AnnouncementLevel level;

  /// App screen opened from the banner; [AppNotificationAction.none] = no link.
  final AppNotificationAction action;
  final DateTime? endsAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    this.level = AnnouncementLevel.info,
    this.action = AppNotificationAction.none,
    this.endsAt,
  });

  /// Null for an item without an id or text (ignored).
  static Announcement? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final title = json['title'];
    final message = json['message'];
    if (id is! String || id.isEmpty || title is! String || message is! String) {
      return null;
    }
    final ends = json['ends_at'];
    return Announcement(
      id: id,
      title: title.trim(),
      message: message.trim(),
      level: json['level'] == 'warning'
          ? AnnouncementLevel.warning
          : AnnouncementLevel.info,
      action: AppNotificationAction.values.firstWhere(
          (a) => a.name == json['action'],
          orElse: () => AppNotificationAction.none),
      endsAt: ends is String ? DateTime.tryParse(ends) : null,
    );
  }

  static List<Announcement> listFromJson(Object? json) => json is List
      ? json.map(fromJson).whereType<Announcement>().toList()
      : const [];

  /// The notification-list id (server limit: 8-64 of A-Z a-z 0-9 -).
  String get notificationId {
    final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '');
    final s = 'ann-$safe';
    return s.length > 64 ? s.substring(0, 64) : s.padRight(8, '0');
  }

  AppNotificationType get notificationType => level == AnnouncementLevel.warning
      ? AppNotificationType.warning
      : AppNotificationType.info;
}
