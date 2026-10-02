import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Horizontal rule with a centred label, e.g. "or".
class OrDivider extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry padding;

  const OrDivider({
    super.key,
    this.label = 'or',
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(label,
                style: AppText.secondary.copyWith(color: AppColors.textMuted)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
