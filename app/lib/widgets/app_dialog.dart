import 'package:flutter/material.dart';
import '../config/theme.dart';

enum AppDialogType { info, warning, danger }

/// White confirmation dialog with a tinted status icon and two actions.
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
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (ctx) => _AppDialogContent(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        type: type,
        icon: icon,
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
  }) async {
    await showDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => _AppDialogContent(
        title: title,
        message: message,
        confirmLabel: actionLabel,
        cancelLabel: null,
        type: type,
        icon: icon,
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

  const _AppDialogContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.type,
    this.icon,
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
          AppColors.warning,
          AppColors.warningTint
        ),
      AppDialogType.danger => (
          Icons.error_rounded,
          AppColors.error,
          AppColors.errorTint
        ),
    };
    final confirmColor =
        type == AppDialogType.danger ? AppColors.error : AppColors.primary;

    return Dialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: AppColors.card,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl, AppSpacing.xxl, AppSpacing.lg, AppSpacing.md),
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
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Text(title, style: AppText.sectionHeader),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Text(message,
                  style:
                      AppText.body14.copyWith(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (cancelLabel != null) ...[
                  _DialogButton(
                    label: cancelLabel!,
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                _DialogButton(
                  label: confirmLabel,
                  color: confirmColor,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        textStyle: AppText.button,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      child: Text(label),
    );
  }
}
