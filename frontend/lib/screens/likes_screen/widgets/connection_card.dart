import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';
import 'package:life_partner_again/widgets/custom_popover_tooltip.dart';

class ConnectionCard extends StatelessWidget {
  final MatchRecommendation profile;
  final int index;
  final VoidCallback? onCancel;

  const ConnectionCard({
    super.key,
    required this.profile,
    required this.index,
    this.onCancel,
  });

  MatchImage? get _profileImage => profile.primaryOrFirstImage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: () {
            context.push('/profile/${profile.id}');
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _profileImage != null
                      ? CachedAppImage(
                          imageId: _profileImage!.imageId,
                          presignedImageUrl: _profileImage!.presignedImageUrl,
                          isBlurred: _profileImage!.isBlurred,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _placeholder(context),
                          errorWidget: (_, __, ___) => _placeholder(context),
                        )
                      : _placeholder(context),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.4, 1.0],
                          colors: [
                            Colors.transparent,
                            AppColors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${profile.name}, ${profile.age}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textWhite,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.isVerified) ...[
                              const SizedBox(width: 4),
                              CustomPopoverTooltip(
                                title: 'Verified Profile',
                                description:
                                    'This profile has been verified and authenticated by our moderation team.',
                                child: Image.asset(
                                  'assets/icons/verified_icon.png',
                                  width: 14,
                                  height: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (profile.city != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 10,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  profile.city!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${profile.matchPercentage}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        cardTheme: CardThemeData(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_vert_rounded,
                            size: 16,
                            color: AppColors.textWhite,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'view',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 18,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color ??
                                      AppColors.textPrimary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'View Profile',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color ??
                                        AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onCancel != null)
                            PopupMenuItem<String>(
                              value: 'cancel',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Cancel Request',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onSelected: (String value) {
                          if (value == 'cancel') {
                            onCancel?.call();
                          } else if (value == 'view') {
                            context.push('/profile/${profile.id}');
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (50 * index.clamp(0, 10)).ms)
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }

  Widget _placeholder(BuildContext context) =>
      Container(color: Theme.of(context).disabledColor.withValues(alpha: 0.1));
}
