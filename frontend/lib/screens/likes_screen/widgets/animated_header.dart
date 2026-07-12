import 'package:flutter/material.dart';

class AnimatedHeader extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const AnimatedHeader({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1.0, // Top aligned
        child: child,
      ),
    );
  }
}
