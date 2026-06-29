import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
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

class _EmptySlotState extends State<EmptySlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.slotIndex == 0 && !widget.isUploading) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EmptySlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slotIndex == 0) {
      if (widget.isUploading) {
        _pulseController.stop();
        _pulseController.animateTo(1.0);
      } else if (!oldWidget.isUploading) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      }
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMain = widget.slotIndex == 0;
    final label = isMain ? 'Main Photo' : 'Photo ${widget.slotIndex + 1}';

    Widget child = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: isMain
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.borderColor,
            borderRadius: 16,
            dashLength: 8,
            gapLength: 6,
            strokeWidth: isMain ? 2.0 : 1.4,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isMain
                  ? AppColors.primary.withValues(alpha: 0.03)
                  : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: widget.isUploading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.primary),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isMain ? 64 : 42,
                        height: isMain ? 64 : 42,
                        decoration: BoxDecoration(
                          color: isMain
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.borderColor.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isMain
                              ? Icons.add_photo_alternate_outlined
                              : Icons.add_rounded,
                          color: isMain
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.6),
                          size: isMain ? 28 : 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: isMain ? 15 : 12,
                          fontWeight:
                              isMain ? FontWeight.w600 : FontWeight.w500,
                          color: isMain
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isMain) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Your first impression',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );

    if (isMain && !widget.isUploading) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: child,
      );
    }

    return child;
  }
}
