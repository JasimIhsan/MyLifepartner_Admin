import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/user_image.dart';

class ImageOptionsBottomSheet extends StatelessWidget {
  final UserImage image;
  final Function(int) onSetPrimary;
  final Function(int) onReplace;

  const ImageOptionsBottomSheet({
    super.key,
    required this.image,
    required this.onSetPrimary,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = image.isPrimary == true;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
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
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const Text(
                    'Photo Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.borderColor, height: 1),
                  const SizedBox(height: 12),
                  if (!isPrimary) ...[
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Set as Main Photo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'This will be the first photo people see',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: () {
                        context.pop();
                        onSetPrimary(image.id);
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Divider(color: AppColors.borderColor, height: 1),
                    ),
                  ],
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 6,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sync_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Replace Photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    subtitle: const Text(
                      'Select a new photo to replace this one',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () {
                      context.pop();
                      onReplace(image.id);
                    },
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => context.pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
