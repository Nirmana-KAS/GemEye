import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/notification_service.dart';

/// 40 px round bell button with a live unread badge ("9+" above 9).
class NotificationBell extends StatelessWidget {
  final VoidCallback onPressed;

  const NotificationBell({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unreadCount,
      builder: (context, count, _) {
        final label = count > 9 ? '9+' : '$count';
        return Semantics(
          button: true,
          label: count == 0 ? 'Notifications' : 'Notifications, $count unread',
          child: SizedBox(
            width: AppSpacing.touchTarget,
            height: AppSpacing.touchTarget,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: AppColors.background,
                    shape: const CircleBorder(
                        side: BorderSide(color: AppColors.border)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onPressed,
                      highlightColor: AppColors.surface,
                      splashColor: Colors.transparent,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.notifications_rounded,
                            size: 24, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: IgnorePointer(
                        child: Container(
                          constraints:
                              const BoxConstraints(minWidth: 20, minHeight: 20),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.background, width: 2),
                          ),
                          child: Text(
                            label,
                            style: AppText.titleSmall.copyWith(
                              fontSize: 10,
                              height: 1,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
