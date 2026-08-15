import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ScannerBase(size: size),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (step) {
      case 0:
        return _FrontOverlay(key: const ValueKey('front'), size: size);
      case 1:
        return _TurnOverlay(
          key: const ValueKey('left'),
          size: size,
          isLeft: true,
        );
      case 2:
        return _TurnOverlay(
          key: const ValueKey('right'),
          size: size,
          isLeft: false,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ScannerBase extends StatelessWidget {
  final double size;

  const _ScannerBase({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
    );
  }
}

class _FrontOverlay extends StatelessWidget {
  final double size;

  const _FrontOverlay({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(size * 0.58, size * 0.68),
          painter: _FaceOvalPainter(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ),
        ),

        Positioned(
          bottom: size * 0.02,
          child: const _InstructionLabel(
            text: 'LOOK STRAIGHT',
            icon: Icons.face_retouching_natural_rounded,
          ),
        ),
      ],
    );
  }
}

class _RunningChevrons extends StatelessWidget {
  final bool isLeft;
  final double size;

  const _RunningChevrons({required this.isLeft, required this.size});

  @override
  Widget build(BuildContext context) {
    final singleChevron = isLeft
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final int animationOrder = isLeft ? (2 - index) : index;
        return Icon(
              singleChevron,
              size: size * 0.16,
              color: Theme.of(context).primaryColor,
            )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(
              begin: 0.25,
              duration: 400.ms,
              delay: (animationOrder * 150).ms,
            )
            .then(delay: 150.ms)
            .fade(begin: 1.0, end: 0.25, duration: 400.ms);
      }),
    );
  }
}

class _TurnOverlay extends StatelessWidget {
  final double size;
  final bool isLeft;

  const _TurnOverlay({super.key, required this.size, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    final labelIcon = isLeft
        ? Icons.arrow_back_rounded
        : Icons.arrow_forward_rounded;

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(size * 0.58, size * 0.68),
          painter: _FaceOvalPainter(
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),

        _RunningChevrons(isLeft: isLeft, size: size),

        Positioned(
          bottom: size * 0.02,
          child: _InstructionLabel(
            text: isLeft ? 'TURN LEFT' : 'TURN RIGHT',
            icon: labelIcon,
          ),
        ),
      ],
    );
  }
}

class _InstructionLabel extends StatelessWidget {
  final String text;
  final IconData icon;

  const _InstructionLabel({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceOvalPainter extends CustomPainter {
  final Color color;

  _FaceOvalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.72,
      height: size.height * 0.85,
    );

    final path = Path()..addOval(rect);

    const dashWidth = 8.0;
    const dashSpace = 6.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            math.min(distance + dashWidth, metric.length),
          ),
          paint,
        );

        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FaceOvalPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
