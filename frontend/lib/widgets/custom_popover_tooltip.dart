import 'package:flutter/material.dart';

class CustomPopoverTooltip extends StatefulWidget {
  final Widget child;
  final String title;
  final String description;

  const CustomPopoverTooltip({
    super.key,
    required this.child,
    required this.title,
    required this.description,
  });

  @override
  State<CustomPopoverTooltip> createState() => _CustomPopoverTooltipState();
}

class _CustomPopoverTooltipState extends State<CustomPopoverTooltip> {
  OverlayEntry? _overlayEntry;

  void _toggleTooltip() {
    if (_overlayEntry != null) {
      _hideTooltip();
    } else {
      _showTooltip();
    }
  }

  void _showTooltip() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final targetOffset = renderBox != null
        ? renderBox.localToGlobal(Offset.zero)
        : Offset.zero;
    final targetSize = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        final padding = mediaQuery.padding;

        const double horizontalMargin = 16.0;
        final double maxTooltipWidth = (screenWidth - (horizontalMargin * 2)).clamp(200.0, 300.0);

        // Center of target element horizontally
        final double targetCenterX = targetOffset.dx + (targetSize.width / 2);

        // Calculate tooltip left position clamped inside screen safe bounds
        double tooltipLeft = targetCenterX - (maxTooltipWidth / 2);
        if (tooltipLeft < horizontalMargin) {
          tooltipLeft = horizontalMargin;
        } else if (tooltipLeft + maxTooltipWidth > screenWidth - horizontalMargin) {
          tooltipLeft = screenWidth - horizontalMargin - maxTooltipWidth;
        }

        // Arrow X position relative to tooltip bubble
        // Keep arrow inside the bubble bounds with border radius in mind
        final double arrowCenterX = (targetCenterX - tooltipLeft).clamp(24.0, maxTooltipWidth - 24.0);

        // Check vertical space (show above if room, else below)
        final bool showAbove = targetOffset.dy > 120 + padding.top;
        final double? tooltipTop = showAbove
            ? null
            : (targetOffset.dy + targetSize.height + 8);
        final double? tooltipBottom = showAbove
            ? (screenHeight - targetOffset.dy + 8)
            : null;

        return Stack(
          children: [
            // Tap backdrop to dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideTooltip,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: tooltipLeft,
              top: tooltipTop,
              bottom: tooltipBottom,
              width: maxTooltipWidth,
              child: Material(
                color: Colors.transparent,
                child: _BubbleWidget(
                  title: widget.title,
                  description: widget.description,
                  arrowPositionX: arrowCenterX,
                  showAbove: showAbove,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleTooltip,
      child: widget.child,
    );
  }
}

class _BubbleWidget extends StatelessWidget {
  final String title;
  final String description;
  final double arrowPositionX;
  final bool showAbove;

  const _BubbleWidget({
    required this.title,
    required this.description,
    required this.arrowPositionX,
    required this.showAbove,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ],
      ),
    );

    final arrow = CustomPaint(
      size: const Size(16, 8),
      painter: _ArrowPainter(
        color: const Color(0xFF141416),
        borderColor: Colors.white.withValues(alpha: 0.15),
        pointDown: showAbove,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!showAbove) ...[
          Padding(
            padding: EdgeInsets.only(left: (arrowPositionX - 8).clamp(0.0, double.infinity)),
            child: arrow,
          ),
        ],
        bubbleContent,
        if (showAbove) ...[
          Padding(
            padding: EdgeInsets.only(left: (arrowPositionX - 8).clamp(0.0, double.infinity)),
            child: arrow,
          ),
        ],
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool pointDown;

  _ArrowPainter({
    required this.color,
    required this.borderColor,
    required this.pointDown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    if (pointDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    }
    path.close();

    canvas.drawPath(path, fillPaint);

    final borderPath = Path();
    if (pointDown) {
      borderPath.moveTo(0, 0);
      borderPath.lineTo(size.width / 2, size.height);
      borderPath.lineTo(size.width, 0);
    } else {
      borderPath.moveTo(0, size.height);
      borderPath.lineTo(size.width / 2, 0);
      borderPath.lineTo(size.width, size.height);
    }
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
