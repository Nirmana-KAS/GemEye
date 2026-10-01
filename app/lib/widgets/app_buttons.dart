import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'loading_indicator.dart';

/// Filled Royal Blue button. Pass a null [onPressed] to disable it.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final String? loadingLabel;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.loadingLabel,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
          Size(AppSpacing.controlHeight, AppSpacing.controlHeight)),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.xxxl)),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg))),
      textStyle: const WidgetStatePropertyAll(AppText.button),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (isLoading) return AppColors.primary;
        if (states.contains(WidgetState.disabled)) return AppColors.border;
        if (states.contains(WidgetState.pressed)) return AppColors.primaryLight;
        return AppColors.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (isLoading) return AppColors.onPrimary;
        if (states.contains(WidgetState.disabled)) return AppColors.textMuted;
        return AppColors.onPrimary;
      }),
    );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const LoadingIndicator.onPrimary(),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.md),
        ],
        Flexible(
          child: Text(
            isLoading ? (loadingLabel ?? label) : label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isLoading && trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: 20),
        ],
      ],
    );

    final button = ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: style,
      child: child,
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: AppSpacing.controlHeight,
      child: button,
    );
  }
}

/// Text-only link button (Forgot password?, Register, Skip).
class TextLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;

  const TextLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
            Size(AppSpacing.touchTarget, AppSpacing.touchTarget)),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.md)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm))),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return AppColors.surface;
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.textMuted;
          if (states.contains(WidgetState.pressed)) return AppColors.primaryLight;
          return AppColors.primary;
        }),
        textStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppText.button
                .copyWith(decoration: TextDecoration.underline);
          }
          return AppText.button;
        }),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label),
          if (trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(trailingIcon, size: 18),
          ],
        ],
      ),
    );
  }
}
