import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Gradient grade hero card: label, "Grade N", name and trade name, the
/// GEMCLOUD reference swatch and a row of pills ([chips]).
class GradeBadgeCard extends StatelessWidget {
  final String label;
  final int gradeNumber;
  final String gradeName;
  final String tradeName;
  final List<Widget> chips;

  const GradeBadgeCard({
    super.key,
    this.label = 'GEMCLOUD GRADE',
    required this.gradeNumber,
    required this.gradeName,
    required this.tradeName,
    this.chips = const [],
  });

  @override
  Widget build(BuildContext context) {
    final swatch = AppColors.grades[(gradeNumber - 1).clamp(0, 6)];
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          colors: [AppColors.grade3, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -28, top: -28, child: _ring(132)),
          Positioned(right: 8, top: 8, child: _ring(76)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: AppText.button.copyWith(
                              fontSize: 11,
                              letterSpacing: 1.5,
                              color: AppColors.grade7,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Grade $gradeNumber',
                            style: AppText.display.copyWith(
                              fontSize: 40,
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '$gradeName - $tradeName',
                            style: AppText.body14Medium
                                .copyWith(color: AppColors.onPrimary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: swatch,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: const [
                          BoxShadow(
                              color: AppColors.onPrimaryRing, spreadRadius: 2),
                        ],
                      ),
                    ),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: chips,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.onPrimarySubtle),
        ),
      );
}

/// Outlined translucent pill for gradient cards ("± 0.2 grade",
/// "Agreed 3 of 3").
class UncertaintyPill extends StatelessWidget {
  final String text;

  const UncertaintyPill({super.key, required this.text});

  /// Pill for a +/- grade range.
  factory UncertaintyPill.range(double range, {Key? key}) =>
      UncertaintyPill(key: key, text: '± $range grade');

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.onPrimaryFaint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.onPrimaryLine),
      ),
      child: Text(
        text,
        style: AppText.button
            .copyWith(fontSize: 11, color: AppColors.onPrimary),
      ),
    );
  }
}
