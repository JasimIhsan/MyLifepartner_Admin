import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mylifepartner/core/app_colors.dart';

/// Animated overlay that visually indicates which face direction
/// the user should present for the current selfie step.
///
/// Steps: 0 = front, 1 = left profile, 2 = right profile.
class FaceDirectionOverlay extends StatelessWidget {
  final int step;
  final double size;

  const FaceDirectionOverlay({
    super.key,
    required this.step,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildForStep(),
      ),
    );
  }

  Widget _buildForStep() {
    switch (step) {
      case 0:
        return _FrontFaceIndicator(key: const ValueKey(0), size: size);
      case 1:
        return _SideIndicator(key: const ValueKey(1), size: size, isLeft: true);
      case 2:
        return _SideIndicator(
          key: const ValueKey(2),
          size: size,
          isLeft: false,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Front face indicator ────────────────────────────────────────────────────
/// A pulsing crosshair/target that says "look straight ahead."
class _FrontFaceIndicator extends StatelessWidget {
  final double size;

  const _FrontFaceIndicator({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing outer ring
          CustomPaint(
            size: Size(size * 0.55, size * 0.55),
            painter: _PulseRingPainter(),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.92, end: 1.06, duration: 1200.ms)
              .fade(begin: 0.3, end: 0.7, duration: 1200.ms),

          // Centre dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.8, end: 1.3, duration: 900.ms),

          // Small crosshair lines
          CustomPaint(
            size: Size(size * 0.35, size * 0.35),
            painter: _CrosshairPainter(),
          ).animate().fade(duration: 600.ms),

          // "Look straight" label at the bottom
          Positioned(
            bottom: size * 0.12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Look straight',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ).animate().fade(duration: 500.ms).slideY(begin: 0.3),
          ),
        ],
      ),
    );
  }
}

// ── Side turn indicator ─────────────────────────────────────────────────────
/// An animated curved arrow telling the user to turn left or right.
class _SideIndicator extends StatelessWidget {
  final double size;
  final bool isLeft;

  const _SideIndicator({
    super.key,
    required this.size,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Curved arrow
          Transform(
            alignment: Alignment.center,
            transform: isLeft
                ? (Matrix4.identity()..setEntry(0, 0, -1.0))
                : Matrix4.identity(),
            child: CustomPaint(
              size: Size(size * 0.7, size * 0.7),
              painter: _CurvedArrowPainter(),
            )
                .animate(onPlay: (c) => c.repeat())
                .fade(begin: 0.4, end: 1.0, duration: 1000.ms)
                .then()
                .fade(begin: 1.0, end: 0.4, duration: 1000.ms),
          ),

          // Bouncing chevrons
          Positioned(
            left: isLeft ? size * 0.08 : null,
            right: isLeft ? null : size * 0.08,
            child: _buildChevrons(),
          ),

          // Label
          Positioned(
            bottom: size * 0.12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLeft ? Icons.arrow_back : Icons.arrow_forward,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLeft ? 'Turn left' : 'Turn right',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 500.ms).slideY(begin: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildChevrons() {
    final icon = isLeft ? Icons.chevron_left : Icons.chevron_right;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Icon(icon, size: 28, color: AppColors.textPrimary.withValues(alpha: 0.7))
            .animate(
              onPlay: (c) => c.repeat(),
              delay: Duration(milliseconds: i * 200),
            )
            .slideX(
              begin: 0,
              end: isLeft ? -0.3 : 0.3,
              duration: 800.ms,
            )
            .fade(begin: 0.3, end: 0.9, duration: 400.ms)
            .then()
            .fade(begin: 0.9, end: 0.0, duration: 400.ms);
      }),
    );
  }
}

// ── Custom painters ─────────────────────────────────────────────────────────

class _PulseRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, paint);

    // Inner dashed ring
    paint
      ..strokeWidth = 1.0
      ..color = AppColors.textPrimary.withValues(alpha: 0.3);
    canvas.drawCircle(center, radius * 0.7, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final gap = size.width * 0.12;
    final arm = size.width * 0.3;

    // Top
    canvas.drawLine(Offset(cx, cy - gap), Offset(cx, cy - gap - arm), paint);
    // Bottom
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + gap + arm), paint);
    // Left
    canvas.drawLine(Offset(cx - gap, cy), Offset(cx - gap - arm, cy), paint);
    // Right
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + gap + arm, cy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CurvedArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.35;

    // Draw arc from ~-30° to ~90° (right side arc)
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    const startAngle = -math.pi / 6;
    const sweepAngle = math.pi * 0.65;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // Arrowhead at the end of the arc
    final endAngle = startAngle + sweepAngle;
    final endX = cx + radius * math.cos(endAngle);
    final endY = cy + radius * math.sin(endAngle);

    final arrowSize = size.width * 0.08;
    final a1 = endAngle - math.pi * 0.7;
    final a2 = endAngle - math.pi * 0.3;

    final path = Path()
      ..moveTo(endX + arrowSize * math.cos(a1), endY + arrowSize * math.sin(a1))
      ..lineTo(endX, endY)
      ..lineTo(
        endX + arrowSize * math.cos(a2),
        endY + arrowSize * math.sin(a2),
      );

    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
