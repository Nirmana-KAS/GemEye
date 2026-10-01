import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Small circular spinner used inside buttons and inline loading states.
class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const LoadingIndicator({
    super.key,
    this.size = 18,
    this.color = AppColors.primary,
    this.trackColor = AppColors.border,
    this.strokeWidth = 2,
  });

  /// White spinner for use on primary-coloured buttons.
  const LoadingIndicator.onPrimary({super.key, this.size = 18})
      : color = AppColors.onPrimary,
        trackColor = AppColors.onPrimaryTrack,
        strokeWidth = 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color,
        backgroundColor: trackColor,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}
