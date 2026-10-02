import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Small bordered metric tile: label, large value, caption.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value $caption',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 30,
              child: Text(
                label,
                maxLines: 2,
                style: AppText.label.copyWith(height: 1.25),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppText.display.copyWith(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              caption,
              style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
