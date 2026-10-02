import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints a dashed outline: a circle when [radius] is null, otherwise a
/// rounded rectangle with that corner radius.
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double? radius;
  final double dash;
  final double gap;

  const DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.radius,
    this.dash = 6,
    this.gap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path();
    if (radius == null) {
      path.addOval(Rect.fromCircle(
          center: rect.center, radius: math.min(rect.width, rect.height) / 2));
    } else {
      path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius!)));
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}
