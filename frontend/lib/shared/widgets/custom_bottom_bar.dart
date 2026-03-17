import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';

class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;
  final Color backgroundColor;
  final Color selectedItemColor;
  final Color unselectedItemColor;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor = Colors.white,
    this.selectedItemColor = AppColors.primary,
    this.unselectedItemColor = AppColors.unselectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = selectedIndex == index;
              final item = items[index];

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 65,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Indicator Line
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutQuint,
                        height: 3,
                        width: isSelected ? 20 : 0,
                        decoration: BoxDecoration(
                          color: selectedItemColor,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                      ),

                      // Icon
                      IconTheme(
                        data: IconThemeData(
                          color: isSelected
                              ? selectedItemColor
                              : unselectedItemColor,
                          size: 24,
                        ),
                        child: item.icon,
                      ),
                      const SizedBox(height: 4),

                      // Label
                      if (item.label != null)
                        Text(
                          item.label!,
                          style: GoogleFonts.poppins(
                            color: isSelected
                                ? selectedItemColor
                                : unselectedItemColor,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
