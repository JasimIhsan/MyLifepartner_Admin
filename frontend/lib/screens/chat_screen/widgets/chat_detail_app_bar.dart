import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';

class ChatDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String profileName;
  final String? profileImageUrl;
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;

  const ChatDetailAppBar({
    super.key,
    required this.profileName,
    this.profileImageUrl,
    required this.onAudioCall,
    required this.onVideoCall,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      leadingWidth: 48,
      title: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surface,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : null,
              child: profileImageUrl == null
                  ? const Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: 20,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              profileName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.call_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: onAudioCall,
                splashRadius: 24,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.videocam_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                onPressed: onVideoCall,
                splashRadius: 24,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.divider, height: 1),
      ),
    );
  }
}
