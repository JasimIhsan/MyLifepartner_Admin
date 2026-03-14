import 'package:flutter/material.dart';

class SwipeActionButtons extends StatelessWidget {
  final VoidCallback onNotInterested;
  final VoidCallback onSkip;
  final VoidCallback onInterested;

  const SwipeActionButtons({
    super.key,
    required this.onNotInterested,
    required this.onSkip,
    required this.onInterested,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          onTap: onNotInterested,
          icon: Icons.close,
          color: Colors.black,
          label: 'Not Interested',
          size: 52,
        ),
        _ActionButton(
          onTap: onSkip,
          icon: Icons.skip_next_rounded,
          color: const Color(0xFF9E9E9E),
          label: 'Skip',
          size: 44,
        ),
        _ActionButton(
          onTap: onInterested,
          icon: Icons.favorite,
          color: Colors.black,
          label: 'Interested',
          size: 52,
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final String label;
  final double size;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.label,
    required this.size,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: widget.size * 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
