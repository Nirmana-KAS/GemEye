import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Static loading block in Primary Surface (System States). Real content
/// replaces it in place.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Swatch + two or three text lines, used for list row skeletons.
class SkeletonRow extends StatelessWidget {
  /// Fractions of the available width for each text line.
  final List<double> lines;

  const SkeletonRow({super.key, this.lines = const [0.6, 0.4]});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SkeletonBox(width: 40, height: 40, radius: AppRadius.md),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  SkeletonBox(
                    width: c.maxWidth * lines[i],
                    height: i == 0 ? 12 : 10,
                    radius: i == 0 ? 6 : 5,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
