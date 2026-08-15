import 'dart:math' as math;

import 'package:flutter/material.dart';

class FoundingMemberBadge extends StatefulWidget {
  final double size;
  final bool isOverlay;
  final bool needAnimation;

  const FoundingMemberBadge({
    super.key,
    this.size = 20,
    this.isOverlay = false,
    this.needAnimation = true,
  });

  @override
  State<FoundingMemberBadge> createState() => _FoundingMemberBadgeState();
}

class _FoundingMemberBadgeState extends State<FoundingMemberBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.needAnimation) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2800),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(FoundingMemberBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.needAnimation != oldWidget.needAnimation) {
      if (widget.needAnimation) {
        _controller ??= AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2800),
        );
        _controller!.repeat();
      } else {
        _controller?.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = widget.size * 1.6;

    final image = Image.asset(
      'assets/icons/founding_icon.png',
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
    );

    if (!widget.needAnimation || _controller == null) {
      return Tooltip(message: 'Founding Member', child: image);
    }

    return Tooltip(
      message: 'Founding Member',
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          final progress = _controller!.value;
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
        child: image,
      ),
    );
  }
}
