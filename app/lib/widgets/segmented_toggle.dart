import 'package:flutter/material.dart';
import '../config/theme.dart';

/// One option in a [SegmentedToggle].
class SegmentOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SegmentOption({required this.value, required this.label, this.icon});
}

/// Two-or-more option toggle with icons. Selected segment is Royal Blue.
class SegmentedToggle<T> extends StatelessWidget {
  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        height: AppSpacing.touchTarget,
        child: Row(
          children: [
            for (final option in options)
              Expanded(child: _segment(option, option.value == selected)),
          ],
        ),
      ),
    );
  }

  Widget _segment(SegmentOption<T> option, bool isSelected) {
    final fg = isSelected ? AppColors.onPrimary : AppColors.textSecondary;
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.surface,
        child: InkWell(
          onTap: isSelected ? null : () => onChanged(option.value),
          splashColor: Colors.transparent,
          highlightColor: AppColors.border,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (option.icon != null) ...[
                Icon(option.icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                option.label,
                style: isSelected
                    ? AppText.button.copyWith(color: fg)
                    : AppText.body14Medium.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
