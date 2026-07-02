import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';

class HeaderWavesBackground extends StatelessWidget {
  final double height;

  const HeaderWavesBackground({
    super.key,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: CustomPaint(
        painter: HeaderWavesPainter(),
      ),
    );
  }
}

class HeaderWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Soft gradient base background
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary.withValues(alpha: 0.12),
        Colors.white.withValues(alpha: 0.0),
      ],
    );
    final paintBg = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paintBg);

    final paint = Paint()..style = PaintingStyle.fill;

    // Layer 1: Softest background wave shape (double wave)
    paint.color = AppColors.primary.withValues(alpha: 0.08);
    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(0, size.height * 0.7);
    path1.cubicTo(
      size.width * 0.25,
      size.height * 0.85,
      size.width * 0.45,
      size.height * 0.45,
      size.width * 0.65,
      size.height * 0.55,
    );
    path1.cubicTo(
      size.width * 0.8,
      size.height * 0.62,
      size.width * 0.9,
      size.height * 0.45,
      size.width,
      size.height * 0.5,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint);

    // Layer 2: Subtle overlapping foreground wave (offset double wave)
    paint.color = AppColors.primary.withValues(alpha: 0.15);
    final path2 = Path();
    path2.moveTo(0, 0);
    path2.lineTo(0, size.height * 0.55);
    path2.cubicTo(
      size.width * 0.25,
      size.height * 0.75,
      size.width * 0.5,
      size.height * 0.35,
      size.width * 0.7,
      size.height * 0.45,
    );
    path2.cubicTo(
      size.width * 0.82,
      size.height * 0.52,
      size.width * 0.92,
      size.height * 0.38,
      size.width,
      size.height * 0.42,
    );
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint);

    // Layer 3: Top-left accent wave
    paint.color = AppColors.primary.withValues(alpha: 0.07);
    final path3 = Path();
    path3.moveTo(0, 0);
    path3.lineTo(0, size.height * 0.35);
    path3.cubicTo(
      size.width * 0.15,
      size.height * 0.45,
      size.width * 0.3,
      size.height * 0.1,
      size.width * 0.45,
      0,
    );
    path3.close();
    canvas.drawPath(path3, paint);

    // Layer 4: Top-right accent wave
    paint.color = AppColors.primary.withValues(alpha: 0.06);
    final path4 = Path();
    path4.moveTo(size.width, 0);
    path4.lineTo(size.width * 0.6, 0);
    path4.cubicTo(
      size.width * 0.75,
      size.height * 0.15,
      size.width * 0.85,
      size.height * 0.3,
      size.width,
      size.height * 0.25,
    );
    path4.close();
    canvas.drawPath(path4, paint);

    // Grid of dots (top right)
    final dotPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    double startX = size.width - 55;
    double startY = 60;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        canvas.drawCircle(
          Offset(startX + (i * 8), startY + (j * 8)),
          1.5,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
