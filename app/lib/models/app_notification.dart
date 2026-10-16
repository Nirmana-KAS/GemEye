enum AppNotificationType { success, warning, error, info }

enum AppNotificationAction {
  none,
  openResult,
  openCalibration,
  openCapture,
  openHistory,
  openPrivacy,
}

/// Notification categories the user can switch off in Settings.
enum NotificationCategory { calibration, referral, certificate }

/// An in-app notification shown in the Notifications screen.
class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final AppNotificationAction action;

  /// Action argument, e.g. the stone ID for [AppNotificationAction.openResult].
  final String? payload;

  /// Settings category; null for notifications that cannot be switched off.
  final NotificationCategory? category;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
    this.action = AppNotificationAction.none,
    this.payload,
    this.category,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        createdAt: createdAt,
        read: read ?? this.read,
        action: action,
        payload: payload,
        category: category,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'action': action.name,
        'payload': payload,
        'category': category?.name,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: _type(json['type']),
        title: json['title'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool? ?? false,
        action: _action(json['action']),
        payload: json['payload'] as String?,
        category: _category(json['category']),
      );

  /// Body item of POST /me/notifications/sync (limits as on the server).
  Map<String, dynamic> toServerJson() => {
        'id': id,
        'type': type.name,
        'category': category?.name,
        'title': _cut(title, 120),
        'message': _cut(message, 1000),
        'action': action.name,
        'payload': payload == null ? null : _cut(payload!, 200),
        'created_at': createdAt.toUtc().toIso8601String(),
        'read': read,
      };

  /// An item of GET /me/notifications.
  factory AppNotification.fromServerJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: _type(json['type']),
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        read: json['read'] as bool? ?? false,
        action: _action(json['action']),
        payload: json['payload'] as String?,
        category: _category(json['category']),
      );

  static String _cut(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);

  static AppNotificationType _type(Object? name) =>
      AppNotificationType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => AppNotificationType.info,
      );

  static AppNotificationAction _action(Object? name) =>
      AppNotificationAction.values.firstWhere(
        (a) => a.name == name,
        orElse: () => AppNotificationAction.none,
      );

  static NotificationCategory? _category(Object? name) =>
      NotificationCategory.values.asNameMap()[name];
}
