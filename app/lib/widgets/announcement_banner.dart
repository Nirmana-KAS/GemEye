import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/announcement_model.dart';
import '../models/app_notification.dart';

/// Home banner for an admin announcement: white bordered card, level colour
/// (info Royal Blue, warning amber), title, message, optional link
/// ([onAction]) and a close button ([onDismiss]).
class AnnouncementBanner extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onDismiss;

  /// Null hides the link (no action, or one Home cannot open).
  final VoidCallback? onAction;

  const AnnouncementBanner({
    super.key,
    required this.announcement,
    required this.onDismiss,
    this.onAction,
  });

  static String actionLabel(AppNotificationAction a) => switch (a) {
        AppNotificationAction.openCalibration => 'Calibrate',
        AppNotificationAction.openCapture => 'Grade a stone',
        AppNotificationAction.openHistory => 'Open history',
        AppNotificationAction.openPrivacy => 'Read privacy policy',
        AppNotificationAction.openResult => 'Open',
        AppNotificationAction.none => '',
      };

  @override
  Widget build(BuildContext context) {
    final warning = announcement.level == AnnouncementLevel.warning;
    final ink = warning ? AppColors.warningText : AppColors.primary;
    final tint = warning ? AppColors.warningTint : AppColors.surface;
    return Semantics(
      container: true,
      label: 'Announcement',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xs, AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(
                  warning ? Icons.warning_amber_rounded : Icons.campaign_rounded,
                  size: 18,
                  color: ink),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxs),
                  Text(announcement.title, style: AppText.titleSmall),
                  if (announcement.message.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(announcement.message,
                        style: AppText.secondary
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                  if (onAction != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    InkWell(
                      onTap: onAction,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(actionLabel(announcement.action),
                                style: AppText.body14Medium
                                    .copyWith(color: ink)),
                            Icon(Icons.chevron_right_rounded,
                                size: 18, color: ink),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss',
              icon: const Icon(Icons.close_rounded,
                  size: 20, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
