import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;
  final Color backgroundColor;
  final Color selectedItemColor;
  final Color unselectedItemColor;
  final VoidCallback? onCenterTap;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor = AppColors.surface,
    this.selectedItemColor = AppColors.primary,
    this.unselectedItemColor = AppColors.unselectedIcon,
    this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    final showCenterButton = onCenterTap != null;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barContentHeight = 60.0;
    const double fabSize = 56.0;
    // The bar itself is only barContentHeight + bottomPadding tall.
    // The FAB overflows above via Clip.none — no extra height reserved.

    return SizedBox(
      height: barContentHeight + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none, // Allows the FAB to overflow above
        children: [
          // ── Bar background with notch ─────────────────────────────────
          Positioned.fill(
            child: showCenterButton
                ? CustomPaint(
                    painter: _BottomBarNotchPainter(
                      color: backgroundColor,
                      notchRadius: fabSize / 2 + 8, // FAB radius + gap
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                  ),
          ),

          // ── Tab items row ─────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: bottomPadding,
            child: Row(children: _buildItems(showCenterButton)),
          ),

          // ── Floating center "+" button (overflows above the bar) ──────
          if (showCenterButton)
            Positioned(
              top: -(fabSize / 2) + 4, // Half the FAB sticks above the bar
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onCenterTap,
                  child: Container(
                    width: fabSize,
                    height: fabSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5F6D), Color(0xFFFF3F3F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildItems(bool showCenterButton) {
    List<Widget> children = [];

    if (showCenterButton) {
      final firstHalf = items.sublist(0, items.length ~/ 2);
      final secondHalf = items.sublist(items.length ~/ 2);

      for (int i = 0; i < firstHalf.length; i++) {
        children.add(Expanded(child: _buildTabItem(i, firstHalf[i])));
      }

      // Center spacer for the floating button
      children.add(const Expanded(child: SizedBox()));

      for (int i = 0; i < secondHalf.length; i++) {
        children.add(
          Expanded(child: _buildTabItem(i + firstHalf.length, secondHalf[i])),
        );
      }
    } else {
      for (int i = 0; i < items.length; i++) {
        children.add(Expanded(child: _buildTabItem(i, items[i])));
      }
    }

    return children;
  }

  Widget _buildTabItem(int index, BottomNavigationBarItem item) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? selectedItemColor : unselectedItemColor;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indicator bar at the top of the tab
          Opacity(
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: 20,
              height: 4,
              decoration: BoxDecoration(
                color: selectedItemColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 6),
          IconTheme(
            data: IconThemeData(color: color, size: 24),
            child: item.icon,
          ),
          const SizedBox(height: 4),
          if (item.label != null)
            Text(
              item.label!,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

/// Paints a bar background with a smooth circular notch cut out at the center top.
class _BottomBarNotchPainter extends CustomPainter {
  final Color color;
  final double notchRadius;

  _BottomBarNotchPainter({required this.color, required this.notchRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Shadow paints – two layers for a natural, visible elevation
    final softShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..style = PaintingStyle.fill;

    final edgeShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final r = notchRadius;

    // Build the path with a smooth notch and sharp top corners
    final path = Path();

    // Start at top-left
    path.moveTo(0, 0);

    // Smooth transition into the notch shoulder + notch itself
    // We curve from (centerX - r - 25, 0) down to the bottom of the notch (centerX, r)
    // using two control points to make a very rounded shoulder transition.
    path.lineTo(centerX - r - 25, 0);
    path.cubicTo(
      centerX - r - 10,
      0, // Shoulder control point: keep it horizontal for a bit
      centerX - r - 5,
      r * 0.15, // Curve entry control point: start bending downwards
      centerX - r,
      r * 0.35, // Entry point to inner notch
    );

    // Deep inner curve to the bottom
    path.cubicTo(
      centerX - r * 0.5,
      r, // Control point 1
      centerX - r * 0.3,
      r, // Control point 2
      centerX,
      r, // Center bottom point
    );

    // Deep inner curve up from bottom
    path.cubicTo(
      centerX + r * 0.3,
      r, // Control point 1
      centerX + r * 0.5,
      r, // Control point 2
      centerX + r,
      r * 0.35, // Exit point from inner notch
    );

    // Smooth transition out of the notch shoulder
    path.cubicTo(
      centerX + r + 5,
      r * 0.15, // Curve exit control point
      centerX + r + 10,
      0, // Shoulder control point
      centerX + r + 25,
      0, // End of curve back on horizontal line
    );

    // Go to top-right corner
    path.lineTo(size.width, 0);

    // Go to bottom-right
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadows first (wide soft + tight edge), then the fill
    canvas.drawPath(path.shift(const Offset(0, -6)), softShadow);
    canvas.drawPath(path.shift(const Offset(0, -2)), edgeShadow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BottomBarNotchPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.notchRadius != notchRadius;
  }
}
