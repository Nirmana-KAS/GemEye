enum AppNotificationType { success, warning, error, info }

enum AppNotificationAction {
  none,
  openResult,
  openCalibration,
  openCapture,
  openHistory,
  openPrivacy,
}

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

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
    this.action = AppNotificationAction.none,
    this.payload,
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
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: AppNotificationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => AppNotificationType.info,
        ),
        title: json['title'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool? ?? false,
        action: AppNotificationAction.values.firstWhere(
          (a) => a.name == json['action'],
          orElse: () => AppNotificationAction.none,
        ),
        payload: json['payload'] as String?,
      );
}
