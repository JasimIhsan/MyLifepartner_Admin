import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_partner_again/core/app_colors.dart';

class AttachmentBottomSheet extends StatelessWidget {
  final Function(String path, String type) onMediaSelected;

  const AttachmentBottomSheet({
    super.key,
    required this.onMediaSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachmentOption(
                    icon: Icons.image_rounded,
                    label: 'Photo',
                    color: Colors.purple.shade400,
                    onTap: () async {
                      context.pop();
                      final picker = ImagePicker();
                      final file = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (file != null) {
                        onMediaSelected(file.path, 'IMAGE');
                      }
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.video_collection_rounded,
                    label: 'Video',
                    color: Colors.orange.shade400,
                    onTap: () async {
                      context.pop();
                      final picker = ImagePicker();
                      final file = await picker.pickVideo(
                        source: ImageSource.gallery,
                      );
                      if (file != null) {
                        onMediaSelected(file.path, 'VIDEO');
                      }
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: Colors.blue.shade400,
                    onTap: () async {
                      context.pop();
                      final picker = ImagePicker();
                      final file = await picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (file != null) {
                        onMediaSelected(file.path, 'IMAGE');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
