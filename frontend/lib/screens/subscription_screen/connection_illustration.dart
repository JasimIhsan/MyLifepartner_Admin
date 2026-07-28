import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

class ConnectionIllustration extends StatelessWidget {
  const ConnectionIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient back glow matching primary brand color
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Custom painted illusion
          CustomPaint(
            size: const Size(120, 110),
            painter: _ConnectionPainter(),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw main glassmorphic backdrop boundary (soft oval)
    final RRect outerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(h / 2),
    );

    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawRRect(outerRRect, bgPaint);

    final Paint borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.7),
          Colors.white.withValues(alpha: 0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(outerRRect, borderPaint);

    // Node 1 (Left - Primary Dark representation)
    final Offset nodeLeft = Offset(w * 0.38, h * 0.52);
    final Paint paintLeft = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary,
          AppColors.primaryDark.withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromCircle(center: nodeLeft, radius: 24))
      ..style = PaintingStyle.fill;

    // Node 2 (Right - Primary Light representation)
    final Offset nodeRight = Offset(w * 0.62, h * 0.48);
    final Paint paintRight = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryLight,
          AppColors.primary.withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromCircle(center: nodeRight, radius: 24))
      ..style = PaintingStyle.fill;

    // Save layer to apply blend mode for overlapping nodes
    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());

    // Draw left and right glowing overlapping circles
    canvas.drawCircle(nodeLeft, 22, paintLeft);
    canvas.drawCircle(nodeRight, 22, paintRight);

    // Draw overlap blending effect
    final Paint blendPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), 15, blendPaint);

    canvas.restore();

    // Draw connecting infinity / heart-like wave path
    final Path wavePath = Path();
    wavePath.moveTo(w * 0.2, h * 0.5);
    wavePath.cubicTo(w * 0.35, h * 0.2, w * 0.45, h * 0.8, w * 0.5, h * 0.5);
    wavePath.cubicTo(w * 0.55, h * 0.2, w * 0.65, h * 0.8, w * 0.8, h * 0.5);

    final Paint pathPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryLight, AppColors.primaryDark],
      ).createShader(Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.6, h * 0.6))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(wavePath, pathPaint);

    // Draw floating sparkles/stars
    _drawSparkle(canvas, Offset(w * 0.25, h * 0.28), 4);
    _drawSparkle(canvas, Offset(w * 0.72, h * 0.72), 5);
    _drawSparkle(canvas, Offset(w * 0.5, h * 0.22), 3);
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius) {
    final Path sparklePath = Path();
    sparklePath.moveTo(center.dx, center.dy - radius);
    sparklePath.quadraticBezierTo(
      center.dx,
      center.dy,
      center.dx + radius,
      center.dy,
    );
    sparklePath.quadraticBezierTo(
      center.dx,
      center.dy,
      center.dx,
      center.dy + radius,
    );
    sparklePath.quadraticBezierTo(
      center.dx,
      center.dy,
      center.dx - radius,
      center.dy,
    );
    sparklePath.quadraticBezierTo(
      center.dx,
      center.dy,
      center.dx,
      center.dy - radius,
    );

    final Paint sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawPath(sparklePath, sparklePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
