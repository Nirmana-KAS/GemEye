import 'package:flutter/material.dart';
import '../config/theme.dart';

/// "Reviewed by gemologist: Grade N" for a stone a gemologist reviewed.
/// [compact] is the History tile line; the full card (Result screen) also
/// shows the reviewer's notes when the API returns them.
class ReviewedGradeBadge extends StatelessWidget {
  final int grade;
  final String? notes;
  final bool compact;

  const ReviewedGradeBadge({
    super.key,
    required this.grade,
    this.notes,
    this.compact = false,
  });

  static String label(int grade) => 'Reviewed by gemologist: Grade $grade';

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        children: [
          const Icon(Icons.verified_user_rounded,
              size: 14, color: AppColors.successText),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(label(grade),
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                    color: AppColors.successText,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      );
    }
    final n = notes?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
                color: AppColors.successTint, shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded,
                size: 18, color: AppColors.successText),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Text(label(grade), style: AppText.titleSmall),
                if (n.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(n,
                      style: AppText.secondary
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
