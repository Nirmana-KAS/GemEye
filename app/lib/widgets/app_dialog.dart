import 'package:flutter/material.dart';
import '../config/theme.dart';

enum AppDialogType { info, warning, danger }

/// White dialog with a tinted status icon, a text cancel action and a filled
/// confirm action (System States). [blocking] dialogs use a darker scrim and
/// cannot be dismissed by tapping outside or pressing back.
class AppDialog {
  /// Returns true when the confirm action is pressed.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    AppDialogType type = AppDialogType.warning,
    IconData? icon,
    bool blocking = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: blocking ? AppColors.scrimBlocking : AppColors.scrim,
      barrierDismissible: !blocking,
      builder: (ctx) => _AppDialogContent(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        type: type,
        icon: icon,
        blocking: blocking,
      ),
    );
    return result ?? false;
  }

  /// Single-action dialog. Completes when the action is pressed or the
  /// dialog is dismissed.
  static Future<void> alert(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
    AppDialogType type = AppDialogType.info,
    IconData? icon,
    bool barrierDismissible = true,
    bool blocking = false,
  }) async {
    await showDialog<bool>(
      context: context,
      barrierColor: blocking ? AppColors.scrimBlocking : AppColors.scrim,
      barrierDismissible: barrierDismissible && !blocking,
      builder: (ctx) => _AppDialogContent(
        title: title,
        message: message,
        confirmLabel: actionLabel,
        cancelLabel: null,
        type: type,
        icon: icon,
        blocking: blocking,
      ),
    );
  }
}

class _AppDialogContent extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final AppDialogType type;
  final IconData? icon;
  final bool blocking;

  const _AppDialogContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.type,
    this.icon,
    this.blocking = false,
  });

  @override
  Widget build(BuildContext context) {
    final (IconData defaultIcon, Color color, Color tint) = switch (type) {
      AppDialogType.info => (
          Icons.info_rounded,
          AppColors.primary,
          AppColors.surface
        ),
      AppDialogType.warning => (
          Icons.warning_rounded,
          AppColors.warningText,
          AppColors.warningTint
        ),
      AppDialogType.danger => (
          Icons.error_rounded,
          AppColors.errorText,
          AppColors.errorTint
        ),
    };
    final confirmColor =
        type == AppDialogType.danger ? AppColors.errorText : AppColors.primary;

    return PopScope(
      canPop: !blocking,
      child: Dialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.xxxl, AppSpacing.xxl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(icon ?? defaultIcon, size: 22, color: color),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: AppText.sectionHeader.copyWith(height: 1.35)),
              const SizedBox(height: AppSpacing.lg),
              Text(message,
                  style: AppText.body14
                      .copyWith(height: 1.5, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (cancelLabel != null) ...[
                    Flexible(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          minimumSize: const Size(
                              AppSpacing.touchTarget, AppSpacing.touchTarget),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          textStyle: AppText.button,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        child: Text(cancelLabel!),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Flexible(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: const Size(
                            AppSpacing.touchTarget, AppSpacing.touchTarget),
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                        textStyle: AppText.button,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
