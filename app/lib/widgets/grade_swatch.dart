import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Rounded colour chip for a GEMCLOUD grade (1 = darkest … 7 = lightest).
class GradeSwatch extends StatelessWidget {
  final int gradeNumber;
  final double size;

  const GradeSwatch({super.key, required this.gradeNumber, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final index = (gradeNumber - 1).clamp(0, AppColors.grades.length - 1);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grades[index],
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.swatchOutline),
      ),
    );
  }
}
