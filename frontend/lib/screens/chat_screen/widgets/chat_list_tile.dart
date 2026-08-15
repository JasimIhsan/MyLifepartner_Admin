import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/chat_provider.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';
import 'package:provider/provider.dart';

class ChatListTile extends StatefulWidget {
  final MatchRecommendation profile;
  final Duration delay;
  final VoidCallback onTap;
  final bool isSelected; // Useful for web to highlight active chat

  const ChatListTile({
    super.key,
    required this.profile,
    required this.delay,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<ChatListTile> createState() => _ChatListTileState();
}

class _ChatListTileState extends State<ChatListTile> {
  bool _isTapped = false;

  MatchImage? get _profileImage => widget.profile.primaryOrFirstImage;

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final conversation = chatProvider.conversations
        .where((c) => c.otherUserId == widget.profile.userId)
        .firstOrNull;
    final lastMessageStr = chatProvider.isUserTyping(widget.profile.userId)
        ? 'typing...'
        : (conversation?.displayLastMessage ?? 'Tap to start chatting');
    final hasUnread = chatProvider.hasUnreadNudge(widget.profile.userId);
    final isOnline = chatProvider.isUserOnline(widget.profile.userId);
    final isTyping = chatProvider.isUserTyping(widget.profile.userId);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onTap,
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                color: _isTapped || widget.isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _buildAvatar(isOnline),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.profile.name,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color ??
                                        AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (hasUnread)
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else if (conversation == null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (lastMessageStr == 'Attachment' ||
                                  lastMessageStr.toLowerCase().contains(
                                    'video call',
                                  ) ||
                                  lastMessageStr.toLowerCase().contains(
                                    'audio call',
                                  )) ...[
                                Icon(
                                  lastMessageStr == 'Attachment'
                                      ? Icons.attachment_rounded
                                      : lastMessageStr.toLowerCase().contains(
                                          'video call',
                                        )
                                      ? Icons.videocam_rounded
                                      : Icons.call_rounded,
                                  size: 14,
                                  color: lastMessageStr.startsWith('Missed')
                                      ? Colors.red
                                      : (hasUnread
                                            ? Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color ??
                                                  AppColors.textPrimary
                                            : Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color ??
                                                  AppColors.textSecondary),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  lastMessageStr,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isTyping
                                        ? Theme.of(context).primaryColor
                                        : (lastMessageStr.startsWith('Missed')
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.error
                                              : (conversation == null
                                                    ? Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.color ??
                                                          AppColors
                                                              .textSecondary
                                                    : (hasUnread
                                                          ? Theme.of(context)
                                                                    .textTheme
                                                                    .bodyLarge
                                                                    ?.color ??
                                                                AppColors
                                                                    .textPrimary
                                                          : Theme.of(context)
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.color ??
                                                                AppColors
                                                                    .textSecondary))),
                                    fontWeight: isTyping || hasUnread
                                        ? FontWeight.w600
                                        : (conversation == null
                                              ? FontWeight.normal
                                              : FontWeight.w400),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: widget.delay, duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildAvatar(bool isOnline) {
    return Stack(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: _profileImage != null
                ? CachedAppImage(
                    imageId: _profileImage!.imageId,
                    presignedImageUrl: _profileImage!.presignedImageUrl,
                    isBlurred: _profileImage!.isBlurred,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildFallbackAvatar(),
                    errorWidget: (_, __, ___) => _buildFallbackAvatar(),
                  )
                : _buildFallbackAvatar(),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          widget.profile.name.isNotEmpty
              ? widget.profile.name[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
