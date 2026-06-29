import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/user_image.dart';

class ImageOptionsBottomSheet extends StatelessWidget {
  final UserImage image;
  final Function(int) onSetPrimary;
  final Function(int) onRemove;

  const ImageOptionsBottomSheet({
    super.key,
    required this.image,
    required this.onSetPrimary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  if (image.isPrimary != true)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      title: const Text(
                        'Set as Main Photo',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'This will be the first photo people see',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onSetPrimary(image.id);
                      },
                    ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFE53935), size: 22),
                    ),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE53935),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onRemove(image.id);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
