import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';

class ChatDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String profileName;
  final int? profileImageId;
  final String? profileImageUrl;
  final bool profileImageIsBlurred;
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;
  final bool isOnline;
  final bool isTyping;

  const ChatDetailAppBar({
    super.key,
    required this.profileName,
    this.profileImageId,
    this.profileImageUrl,
    this.profileImageIsBlurred = false,
    required this.onAudioCall,
    required this.onVideoCall,
    this.isOnline = false,
    this.isTyping = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:
          Theme.of(
            context,
          ).appBarTheme.backgroundColor?.withValues(alpha: 0.95) ??
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 1,
      surfaceTintColor: Theme.of(context).colorScheme.surface,
      foregroundColor:
          Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      leadingWidth: 48,
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: ClipOval(
                    child: profileImageId != null || profileImageUrl != null
                        ? CachedAppImage(
                            imageId: profileImageId,
                            presignedImageUrl: profileImageUrl,
                            isBlurred: profileImageIsBlurred,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                _buildAvatarFallback(context),
                            errorWidget: (_, __, ___) =>
                                _buildAvatarFallback(context),
                          )
                        : _buildAvatarFallback(context),
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  profileName,
                  style: TextStyle(
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isTyping)
                  Text(
                    'typing...',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: isOnline
                          ? Colors.green
                          : Theme.of(context).textTheme.bodyMedium?.color ??
                                AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.call_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                onPressed: onAudioCall,
                splashRadius: 24,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.videocam_rounded,
                  color: Theme.of(context).primaryColor,
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
        child: Container(color: Theme.of(context).dividerColor, height: 1),
      ),
    );
  }

  Widget _buildAvatarFallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Icon(
        Icons.person,
        color:
            Theme.of(context).textTheme.bodyMedium?.color ??
            AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}
