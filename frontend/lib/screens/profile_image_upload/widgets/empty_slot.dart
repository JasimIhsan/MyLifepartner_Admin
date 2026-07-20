import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'dashed_border_painter.dart';

class EmptySlot extends StatefulWidget {
  final int slotIndex;
  final bool isUploading;
  final VoidCallback? onTap;

  const EmptySlot({
    super.key,
    required this.slotIndex,
    required this.isUploading,
    this.onTap,
  });

  @override
  State<EmptySlot> createState() => _EmptySlotState();
}

class _EmptySlotState extends State<EmptySlot> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isMain = widget.slotIndex == 0;
    final label = isMain ? 'Main Photo' : 'Photo ${widget.slotIndex + 1}';

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: CustomPaint(
                  painter: DashedBorderPainter(
                    color: isMain ? AppColors.primary : AppColors.borderColor,
                    borderRadius: 16,
                    dashLength: 7,
                    gapLength: 5,
                    strokeWidth: isMain ? 1.8 : 1.4,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isMain
                          ? AppColors.primary.withValues(alpha: 0.04)
                          : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: widget.isUploading
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isMain
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : AppColors.borderColor.withValues(
                                          alpha: 0.5,
                                        ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isMain
                                      ? Icons.add_photo_alternate_outlined
                                      : Icons.add_rounded,
                                  color: isMain
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  size: isMain ? 24 : 22,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isMain
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isMain
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              if (isMain) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'First impression',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              )
              .animate(target: _isPressed ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(0.95, 0.95),
                duration: 150.ms,
                curve: Curves.easeOutCubic,
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .fade(
                begin: 0.8,
                end: 1.0,
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),
    );
  }
}
