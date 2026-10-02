import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/connectivity_service.dart';

enum StatusBannerType { success, warning, error }

/// White bordered row with a coloured status dot (or [icon]), message and
/// either a chevron ([onTap]) or a text action ([actionLabel]).
class StatusBanner extends StatelessWidget {
  final StatusBannerType type;
  final String message;
  final VoidCallback? onTap;

  /// Replaces the status dot (e.g. wifi_off for the offline banner).
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StatusBanner({
    super.key,
    required this.type,
    required this.message,
    this.onTap,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final (Color dot, Color halo, Color ink) = switch (type) {
      StatusBannerType.success =>
        (AppColors.success, AppColors.successTint, AppColors.successText),
      StatusBannerType.warning =>
        (AppColors.warning, AppColors.warningTint, AppColors.warningText),
      StatusBannerType.error =>
        (AppColors.error, AppColors.errorTint, AppColors.errorText),
    };
    final hasAction = actionLabel != null && onAction != null;

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        highlightColor: AppColors.surface,
        splashColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
          padding: hasAction
              ? const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs)
              : const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
          child: Row(
            children: [
              if (icon != null)
                Icon(icon, size: 20, color: ink)
              else
                Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(color: halo, shape: BoxShape.circle),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  message,
                  style: AppText.body14Medium.copyWith(height: 1.35),
                ),
              ),
              if (hasAction)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(
                        AppSpacing.touchTarget, AppSpacing.touchTarget),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    textStyle: AppText.button.copyWith(fontSize: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                  child: Text(actionLabel!),
                )
              else if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// "You're offline" banner with Retry, shown only while
/// [ConnectivityService.online] is false.
class OfflineBanner extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const OfflineBanner({super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.online,
      builder: (context, online, _) {
        if (online) return const SizedBox.shrink();
        return Padding(
          padding: padding,
          child: const StatusBanner(
            type: StatusBannerType.error,
            icon: Icons.wifi_off_rounded,
            message: "You're offline - grading needs a connection",
            actionLabel: 'Retry',
            onAction: ConnectivityService.check,
          ),
        );
      },
    );
  }
}
