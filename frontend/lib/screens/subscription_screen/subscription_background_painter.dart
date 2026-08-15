import 'package:flutter/material.dart';

class SubscriptionBackground extends StatelessWidget {
  const SubscriptionBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: SubscriptionBackgroundPainter(Theme.of(context)),
        size: Size.infinite,
      ),
    );
  }
}

class SubscriptionBackgroundPainter extends CustomPainter {
  final ThemeData theme;

  SubscriptionBackgroundPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final bool isDark = theme.brightness == Brightness.dark;

    Color c(Color light, Color dark) => isDark ? dark : light;

    // 1. Clean backdrop base gradient (White to very Light Gray/Slate)
    final Rect rect = Rect.fromLTWH(0, 0, w, h);
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          c(const Color(0xFFFCFCFD), theme.scaffoldBackgroundColor),
          c(const Color(0xFFF8FAFC), theme.colorScheme.surface),
          c(const Color(0xFFF1F5F9), theme.scaffoldBackgroundColor),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Grid of subtle decorative background dots
    final Paint dotPaint = Paint()
      ..color = c(
        const Color(0xFFE2E8F0).withValues(alpha: 0.25),
        Colors.white.withValues(alpha: 0.05),
      )
      ..style = PaintingStyle.fill;
    const double spacing = 24.0;
    for (double x = spacing / 2; x < w; x += spacing) {
      for (double y = spacing / 2; y < h; y += spacing) {
        // Only draw dots in certain non-crowded background regions
        if ((x < w * 0.45 && y < h * 0.3) || (x > w * 0.55 && y > h * 0.65)) {
          canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
        }
      }
    }

    final Paint wavePaint = Paint()..style = PaintingStyle.fill;

    // 3. Layer A: Top-Left to Center Fluid Wave (Gradient fill)
    final Path pathA = Path();
    pathA.moveTo(0, 0);
    pathA.lineTo(w * 0.85, 0);
    pathA.cubicTo(w * 0.6, h * 0.15, w * 0.3, h * 0.1, 0, h * 0.32);
    pathA.close();
    wavePaint.shader = LinearGradient(
      colors: [
        c(
          const Color(0xFFE2E8F0).withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.04),
        ),
        c(
          const Color(0xFFF1F5F9).withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.01),
        ),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, w * 0.85, h * 0.32));
    canvas.drawPath(pathA, wavePaint);

    // 4. Layer B: Top-Right Overlapping Sinuous Wave
    final Path pathB = Path();
    pathB.moveTo(w, 0);
    pathB.lineTo(w * 0.25, 0);
    pathB.cubicTo(w * 0.45, h * 0.2, w * 0.75, h * 0.15, w, h * 0.48);
    pathB.close();
    wavePaint.shader = LinearGradient(
      colors: [
        c(
          const Color(0xFFCBD5E1).withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.05),
        ),
        c(
          const Color(0xFFE2E8F0).withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.02),
        ),
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ).createShader(Rect.fromLTWH(w * 0.25, 0, w * 0.75, h * 0.48));
    canvas.drawPath(pathB, wavePaint);

    // 5. Layer C: Premium Diagonal Wave Ribbon (Flowing through middle behind the cards)
    final Path pathC = Path();
    pathC.moveTo(0, h * 0.38);
    pathC.cubicTo(w * 0.35, h * 0.48, w * 0.65, h * 0.28, w, h * 0.44);
    pathC.lineTo(w, h * 0.62);
    pathC.cubicTo(w * 0.65, h * 0.48, w * 0.35, h * 0.66, 0, h * 0.54);
    pathC.close();
    wavePaint.shader = LinearGradient(
      colors: [
        c(
          const Color(0xFFF1F5F9).withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.03),
        ),
        c(
          const Color(0xFFE2E8F0).withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.06),
        ),
        c(
          const Color(0xFFF8FAFC).withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.01),
        ),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(0, h * 0.28, w, h * 0.38));
    canvas.drawPath(pathC, wavePaint);

    // 6. Layer D: Bottom-Left to Bottom-Right Double-Hump Wave
    final Path pathD = Path();
    pathD.moveTo(0, h);
    pathD.lineTo(0, h * 0.78);
    pathD.cubicTo(w * 0.25, h * 0.72, w * 0.45, h * 0.88, w * 0.7, h * 0.82);
    pathD.cubicTo(w * 0.85, h * 0.78, w * 0.93, h * 0.84, w, h * 0.82);
    pathD.lineTo(w, h);
    pathD.close();
    wavePaint.shader = LinearGradient(
      colors: [
        c(
          const Color(0xFFCBD5E1).withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.08),
        ),
        c(
          const Color(0xFFF1F5F9).withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.04),
        ),
      ],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ).createShader(Rect.fromLTWH(0, h * 0.72, w, h * 0.28));
    canvas.drawPath(pathD, wavePaint);

    // 7. Layer E: Secondary Bottom Rising Wave Overlay
    final Path pathE = Path();
    pathE.moveTo(0, h);
    pathE.lineTo(0, h * 0.86);
    pathE.cubicTo(w * 0.3, h * 0.9, w * 0.6, h * 0.78, w, h * 0.88);
    pathE.lineTo(w, h);
    pathE.close();
    wavePaint.shader = LinearGradient(
      colors: [
        c(
          const Color(0xFFE2E8F0).withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.05),
        ),
        c(
          const Color(0xFFF8FAFC).withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.02),
        ),
      ],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ).createShader(Rect.fromLTWH(0, h * 0.78, w, h * 0.22));
    canvas.drawPath(pathE, wavePaint);

    // 8. Thin premium wireframe curve lines (Adding design details)
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Top wireframe curve line
    final Path linePath1 = Path();
    linePath1.moveTo(0, h * 0.28);
    linePath1.cubicTo(w * 0.4, h * 0.12, w * 0.7, h * 0.22, w, h * 0.08);
    linePaint.shader = LinearGradient(
      colors: [
        c(
          const Color(0xFFCBD5E1).withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.1),
        ),
        c(
          const Color(0xFFCBD5E1).withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ),
      ],
    ).createShader(Rect.fromLTWH(0, h * 0.08, w, h * 0.2));
    canvas.drawPath(linePath1, linePaint);

    // Bottom wireframe curve line
    final Path linePath2 = Path();
    linePath2.moveTo(0, h * 0.85);
    linePath2.cubicTo(w * 0.35, h * 0.76, w * 0.65, h * 0.92, w, h * 0.8);
    linePaint.shader = LinearGradient(
      colors: [
        c(
          const Color(0xFFCBD5E1).withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ),
        c(
          const Color(0xFFCBD5E1).withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.15),
        ),
        c(
          const Color(0xFFCBD5E1).withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
        ),
      ],
    ).createShader(Rect.fromLTWH(0, h * 0.76, w, h * 0.16));
    canvas.drawPath(linePath2, linePaint);
  }

  @override
  bool shouldRepaint(covariant SubscriptionBackgroundPainter oldDelegate) {
    return oldDelegate.theme.brightness != theme.brightness;
  }
}
