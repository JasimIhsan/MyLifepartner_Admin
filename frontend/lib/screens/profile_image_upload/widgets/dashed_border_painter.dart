import 'dart:math' as math;
import 'package:flutter/material.dart';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double borderRadius;

  const DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    this.strokeWidth = 1.5,
    this.dashLength = 6,
    this.gapLength = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = borderRadius;
    final w = size.width;
    final h = size.height;

    // Build the full path of the rounded rectangle
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(r),
    );
    final path = Path()..addRRect(rrect);

    // Measure total path length
    final metrics = path.computeMetrics().toList();

    // Draw dashes
    bool drawing = true;

    for (final metric in metrics) {
      double pos = 0;
      while (pos < metric.length) {
        final remaining = metric.length - pos;
        final segment = math.min(drawing ? dashLength : gapLength, remaining);

        if (drawing) {
          final extractedPath = metric.extractPath(pos, pos + segment);
          canvas.drawPath(extractedPath, paint);
        }

        pos += segment;

        if ((drawing && segment >= dashLength) ||
            (!drawing && segment >= gapLength)) {
          drawing = !drawing;
        }
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength ||
      old.borderRadius != borderRadius;
}
