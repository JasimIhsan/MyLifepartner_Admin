import 'dart:math' as math;

import 'package:flutter/material.dart';

class FoundingMemberBadge extends StatefulWidget {
  final double size;
  final bool isOverlay;

  const FoundingMemberBadge({
    super.key,
    this.size = 20,
    this.isOverlay = false,
  });

  @override
  State<FoundingMemberBadge> createState() => _FoundingMemberBadgeState();
}

class _FoundingMemberBadgeState extends State<FoundingMemberBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = widget.size * 1.6;

    return Tooltip(
      message: 'Founding Member',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          final flipProgress = progress < 0.45
              ? Curves.easeInOutCubic.transform(progress / 0.45)
              : 0.0;
          final angle = flipProgress * math.pi * 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: child,
          );
        },
        child: Image.asset(
          'assets/icons/founding_icon.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
