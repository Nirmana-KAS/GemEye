import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 20 px rounded checkbox with a tappable label. The whole row is the
/// touch target (min 48 dp).
class AppCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget label;

  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final Color borderColor;
    final Color fillColor;
    if (!enabled) {
      borderColor = AppColors.border;
      fillColor = value ? AppColors.border : AppColors.background;
    } else {
      borderColor = value ? AppColors.primary : AppColors.textMuted;
      fillColor = value ? AppColors.primary : AppColors.background;
    }

    return Semantics(
      checked: value,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: AppSpacing.touchTarget),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: value && enabled ? fillColor : borderColor,
                    width: 2,
                  ),
                ),
                child: value
                    ? Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: enabled
                            ? AppColors.onPrimary
                            : AppColors.textMuted,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: AppText.body14.copyWith(
                    height: 1.4,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                  child: label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
