import 'package:flutter/material.dart';
import '../config/theme.dart';

/// White card with a 1 px border. Never coloured, never a gradient.
class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const CardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadius.lg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        highlightColor: AppColors.surface,
        splashColor: Colors.transparent,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
