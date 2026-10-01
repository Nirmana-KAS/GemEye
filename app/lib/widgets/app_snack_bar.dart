import 'package:flutter/material.dart';
import '../config/theme.dart';

enum AppSnackBarType { success, info, warning, error }

/// Floating white snackbar with a tinted status icon and optional action.
class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        duration: duration,
        content: _AppSnackBarContent(
          message: message,
          type: type,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
        ),
      ),
    );
  }
}

class _AppSnackBarContent extends StatelessWidget {
  final String message;
  final AppSnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AppSnackBarContent({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, Color tint) = switch (type) {
      AppSnackBarType.success => (
          Icons.check_circle_rounded,
          AppColors.success,
          AppColors.successTint
        ),
      AppSnackBarType.info =>
        (Icons.info_rounded, AppColors.primary, AppColors.surface),
      AppSnackBarType.warning => (
          Icons.warning_rounded,
          AppColors.warning,
          AppColors.warningTint
        ),
      AppSnackBarType.error =>
        (Icons.error_rounded, AppColors.error, AppColors.errorTint),
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              message,
              style: AppText.body14Medium.copyWith(height: 1.35),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(AppSpacing.touchTarget, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                textStyle: AppText.button.copyWith(fontSize: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm)),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
