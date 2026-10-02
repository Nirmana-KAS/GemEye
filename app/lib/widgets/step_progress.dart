import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Horizontal numbered stepper: done steps show a green check, the active
/// step is Royal Blue with a halo, pending steps are outlined.
class StepProgress extends StatelessWidget {
  final List<String> labels;
  final int current;

  const StepProgress({super.key, required this.labels, required this.current});

  static const double _dot = 24;

  @override
  Widget build(BuildContext context) {
    final count = labels.length;
    return LayoutBuilder(builder: (context, constraints) {
      final cell = constraints.maxWidth / count;
      final lineStart = cell / 2;
      final lineFull = constraints.maxWidth - cell;
      final done = current.clamp(0, count - 1) / (count - 1);
      return Stack(
        children: [
          Positioned(
            left: lineStart,
            width: lineFull,
            top: _dot / 2 - 1,
            height: 2,
            child: const ColoredBox(color: AppColors.border),
          ),
          Positioned(
            left: lineStart,
            width: lineFull * done,
            top: _dot / 2 - 1,
            height: 2,
            child: const ColoredBox(color: AppColors.success),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(width: cell, child: _buildStep(i)),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildStep(int i) {
    final isDone = i < current;
    final isActive = i == current;
    final Widget dot;
    if (isDone) {
      dot = Container(
        width: _dot,
        height: _dot,
        decoration: const BoxDecoration(
            color: AppColors.success, shape: BoxShape.circle),
        child:
            const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary),
      );
    } else if (isActive) {
      dot = Container(
        width: _dot,
        height: _dot,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.surface, spreadRadius: 4)],
        ),
        child: Text('${i + 1}',
            style: AppText.button
                .copyWith(fontSize: 11, color: AppColors.onPrimary)),
      );
    } else {
      dot = Container(
        width: _dot,
        height: _dot,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Text('${i + 1}',
            style: AppText.button
                .copyWith(fontSize: 11, color: AppColors.textMuted)),
      );
    }
    return Column(
      children: [
        dot,
        const SizedBox(height: AppSpacing.sm),
        Text(
          labels[i],
          textAlign: TextAlign.center,
          style: isActive
              ? AppText.button.copyWith(
                  fontSize: 11, height: 1.2, color: AppColors.primary)
              : AppText.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color:
                      isDone ? AppColors.textPrimary : AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Vertical stepper: done steps show a green check joined by a green line,
/// the active step shows a spinner and a SemiBold label, pending steps are
/// outlined and muted.
class VerticalStepProgress extends StatelessWidget {
  final List<String> labels;
  final int current;

  const VerticalStepProgress(
      {super.key, required this.labels, required this.current});

  static const double _dot = 28;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < labels.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _dot,
                  child: Column(
                    children: [
                      _buildDot(i),
                      if (i < labels.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            constraints: const BoxConstraints(minHeight: 12),
                            margin: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs),
                            color: i < current
                                ? AppColors.success
                                : AppColors.border,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: AppSpacing.xs, bottom: 14),
                    child: Text(
                      labels[i],
                      style: i == current
                          ? AppText.titleSmall.copyWith(height: 1.4)
                          : AppText.body14.copyWith(
                              height: 1.4,
                              color: i > current
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDot(int i) {
    if (i < current) {
      return Container(
        width: _dot,
        height: _dot,
        decoration: const BoxDecoration(
            color: AppColors.success, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded,
            size: 18, color: AppColors.onPrimary),
      );
    }
    if (i == current) {
      return Container(
        width: _dot,
        height: _dot,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: AppColors.surface, shape: BoxShape.circle),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
            backgroundColor: AppColors.border,
          ),
        ),
      );
    }
    return Container(
      width: _dot,
      height: _dot,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Text('${i + 1}',
          style: AppText.button
              .copyWith(fontSize: 12, color: AppColors.textMuted)),
    );
  }
}
