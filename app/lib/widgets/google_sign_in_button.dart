import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'loading_indicator.dart';

/// "Continue with Google" button following Google sign-in branding:
/// white, 1 px #747775 border, Roboto Medium 14, #1F1F1F label.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final String loadingLabel;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Continue with Google',
    this.loadingLabel = 'Signing in…',
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.controlHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSpacing.xl)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg))),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStatePropertyAll(BorderSide(
            color: disabled
                ? AppColors.googleDisabledBorder
                : AppColors.googleBorder,
          )),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.googlePressed;
            }
            return AppColors.background;
          }),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const LoadingIndicator(
                color: AppColors.googleBorder,
                trackColor: AppColors.border,
              )
            else
              Opacity(
                opacity: disabled ? 0.38 : 1,
                child: Image.asset(
                  'assets/images/google_logo.png',
                  width: 20,
                  height: 20,
                ),
              ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              isLoading ? loadingLabel : label,
              style: AppText.googleButton.copyWith(
                color: disabled
                    ? AppColors.googleDisabledText
                    : AppColors.googleText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
