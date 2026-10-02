import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'card_container.dart';

/// "How sure is the model" card: one bar per GEMCLOUD grade (G1-G7).
/// [probabilities] are percentages (0-100) in grade order; the bar of
/// [predictedGrade] (1-7) is highlighted.
class ProbabilityBarCard extends StatelessWidget {
  final List<double> probabilities;
  final int predictedGrade;

  const ProbabilityBarCard({
    super.key,
    required this.probabilities,
    required this.predictedGrade,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                  child: Text('How sure is the model',
                      style: AppText.titleSmall)),
              Text('Ensemble output', style: AppText.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < probabilities.length && i < 7; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            ProbabilityBar(
              grade: i + 1,
              percent: probabilities[i],
              highlighted: i + 1 == predictedGrade,
            ),
          ],
        ],
      ),
    );
  }
}

/// One grade row: swatch, "G n", bar and percentage.
class ProbabilityBar extends StatelessWidget {
  final int grade;
  final double percent;
  final bool highlighted;

  const ProbabilityBar({
    super.key,
    required this.grade,
    required this.percent,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = highlighted
        ? AppText.button.copyWith(fontSize: 11, color: AppColors.primary)
        : AppText.caption.copyWith(color: AppColors.textSecondary);
    final pctText = percent < 1 ? '<1%' : '${percent.round()}%';
    return SizedBox(
      height: 16,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.grades[grade - 1],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 20, child: Text('G$grade', style: labelStyle)),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  Container(height: 6, color: AppColors.surface),
                  FractionallySizedBox(
                    widthFactor: math.max(percent, 0.6).clamp(0, 100) / 100,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: highlighted
                            ? AppColors.primary
                            : AppColors.textMuted,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(pctText,
                textAlign: TextAlign.right,
                style: labelStyle.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ],
      ),
    );
  }
}
