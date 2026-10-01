import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Pill showing confidence level: High ≥ 60 (green), Borderline 40–59
/// (amber), Low < 40 (red). [confidence] is a percentage (0–100).
class ConfidenceBadge extends StatelessWidget {
  static const double referThreshold = 60;
  static const double lowThreshold = 40;

  final double confidence;

  const ConfidenceBadge({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final (String level, Color dot, Color tint) = confidence >= referThreshold
        ? ('High', AppColors.success, AppColors.successTint)
        : confidence >= lowThreshold
            ? ('Borderline', AppColors.warning, AppColors.warningTint)
            : ('Low', AppColors.error, AppColors.errorTint);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$level · ${confidence.round()}%',
            style: AppText.titleSmall.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
