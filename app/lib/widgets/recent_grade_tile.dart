import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import 'confidence_badge.dart';
import 'grade_swatch.dart';
import 'relative_time.dart';

/// One graded stone in a list: swatch, grade, stone ID, time, confidence and
/// a "Referred" chip below the referral threshold.
class RecentGradeTile extends StatelessWidget {
  final GradeResult result;
  final bool showTopBorder;
  final VoidCallback? onTap;

  const RecentGradeTile({
    super.key,
    required this.result,
    this.showTopBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final referred = result.isReferred;

    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: onTap,
        highlightColor: AppColors.surface,
        splashColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            border: showTopBorder
                ? const Border(top: BorderSide(color: AppColors.border))
                : null,
          ),
          child: Row(
            children: [
              GradeSwatch(gradeNumber: result.gradeNumber),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grade ${result.gradeNumber} · ${result.gradeName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(result.stoneId,
                        style: AppText.secondary.copyWith(height: 1.35)),
                    Text(formatRelativeTime(result.capturedAt),
                        style: AppText.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ConfidenceBadge(confidence: result.confidence),
                  if (referred) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      height: 20,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warningTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flag_rounded,
                              size: 12, color: AppColors.warning),
                          const SizedBox(width: AppSpacing.xs),
                          Text('Referred',
                              style: AppText.titleSmall.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
