import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/app_notification.dart';
import 'relative_time.dart';

/// Icon, foreground and tint for each notification type.
(IconData, Color, Color) notificationStyle(AppNotificationType type) =>
    switch (type) {
      AppNotificationType.success => (
          Icons.check_circle_rounded,
          AppColors.success,
          AppColors.successTint
        ),
      AppNotificationType.warning => (
          Icons.warning_rounded,
          AppColors.warning,
          AppColors.warningTint
        ),
      AppNotificationType.error => (
          Icons.error_rounded,
          AppColors.error,
          AppColors.errorTint
        ),
      AppNotificationType.info => (
          Icons.info_rounded,
          AppColors.primary,
          AppColors.surface
        ),
    };

/// One row in the Notifications list. Unread rows have a Primary Surface
/// background and a Royal Blue dot. Swipe left to delete.
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, tint) = notificationStyle(notification.type);
    final unread = !notification.read;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_rounded, color: AppColors.onPrimary),
            const SizedBox(height: AppSpacing.xxs),
            Text('Delete',
                style: AppText.titleSmall
                    .copyWith(fontSize: 11, color: AppColors.onPrimary)),
          ],
        ),
      ),
      child: Material(
        color: unread ? AppColors.surface : AppColors.background,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: AppColors.border,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                      BoxDecoration(color: tint, shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.titleSmall,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(formatRelativeTime(notification.createdAt),
                              style: AppText.caption),
                          if (unread) ...[
                            const SizedBox(width: AppSpacing.md),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        notification.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.secondary.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
