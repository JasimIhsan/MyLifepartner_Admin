import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/user_image.dart';

class FilledSlot extends StatefulWidget {
  final UserImage image;
  final int slotIndex;
  final VoidCallback onTap;
  final bool isProcessing;

  const FilledSlot({
    super.key,
    required this.image,
    required this.slotIndex,
    required this.onTap,
    this.isProcessing = false,
  });

  @override
  State<FilledSlot> createState() => _FilledSlotState();
}

class _FilledSlotState extends State<FilledSlot> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.image.isPrimary == true;
    return GestureDetector(
      onTapDown: widget.isProcessing
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isProcessing
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _isPressed = false),
      child:
          Stack(
                clipBehavior: Clip.none,
                children: [
                  // Image card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isPrimary
                          ? Border.all(color: AppColors.primary, width: 2.5)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        isPrimary ? 13.5 : 16,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: widget.image.imageUrl,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 300),
                            placeholder: (_, __) => Container(
                              color: AppColors.primaryLight,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.primaryLight,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ).animate().scale(
                            duration: 10.seconds,
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                            curve: Curves.linear,
                          ),
                          if (widget.isProcessing)
                            ClipRRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 200.ms),
                        ],
                      ),
                    ),
                  ),

                  // Primary badge
                  if (isPrimary)
                    Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Main Photo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .slideY(begin: 0.5, end: 0, duration: 300.ms)
                        .fadeIn(),

                  // Edit indicator (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Slot number badge (top-left) for non-primary
                  if (!isPrimary)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.slotIndex + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
              .animate(target: _isPressed ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(0.95, 0.95),
                duration: 150.ms,
                curve: Curves.easeOutCubic,
              ),
    );
  }
}
