import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/settings_service.dart';

/// Pill showing confidence level: High unless the stone was referred
/// (green), Borderline when referred and down to 40 (amber), Low below 40
/// (red). [confidence] is a percentage (0-100). [referred] is the stone's own
/// flag (`GradeResult.isReferred`); without it the current Settings threshold
/// (default 60) decides.
class ConfidenceBadge extends StatelessWidget {
  /// Referral threshold from Settings (single source of truth).
  static double get referThreshold =>
      SettingsService.referralThreshold.value;
  static const double lowThreshold = 40;

  final double confidence;
  final bool? referred;

  /// White text on a translucent pill, for gradient grade cards.
  final bool onDark;

  const ConfidenceBadge(
      {super.key,
      required this.confidence,
      this.referred,
      this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final isReferred = referred ?? confidence < referThreshold;
    final (String level, Color dot, Color tint) = !isReferred
        ? ('High', AppColors.success, AppColors.successTint)
        : confidence >= lowThreshold
            ? ('Borderline', AppColors.warning, AppColors.warningTint)
            : ('Low', AppColors.error, AppColors.errorTint);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: onDark ? AppColors.onPrimaryFaint : tint,
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
            style: AppText.titleSmall.copyWith(
                fontSize: 11, color: onDark ? AppColors.onPrimary : null),
          ),
        ],
      ),
    );
  }
}
