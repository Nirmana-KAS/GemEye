import 'package:flutter/material.dart';
import '../config/theme.dart';

enum StatusBannerType { success, warning, error }

/// White bordered row with a coloured status dot, message and chevron.
class StatusBanner extends StatelessWidget {
  final StatusBannerType type;
  final String message;
  final VoidCallback? onTap;

  const StatusBanner({
    super.key,
    required this.type,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (Color dot, Color halo) = switch (type) {
      StatusBannerType.success => (AppColors.success, AppColors.successTint),
      StatusBannerType.warning => (AppColors.warning, AppColors.warningTint),
      StatusBannerType.error => (AppColors.error, AppColors.errorTint),
    };

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
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: halo, shape: BoxShape.circle),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: AppSpacing.lg - 4),
              Expanded(
                child: Text(
                  message,
                  style: AppText.body14Medium.copyWith(height: 1.35),
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
