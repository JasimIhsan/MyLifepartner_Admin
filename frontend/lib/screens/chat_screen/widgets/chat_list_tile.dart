import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/providers/chat_provider.dart';
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

  String? get _imageUrl {
    final primary = widget.profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    if (widget.profile.images.isNotEmpty) {
      return widget.profile.images.first.imageUrl;
    }
    return null;
  }

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _isTapped || widget.isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
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
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
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
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
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
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
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
                          lastMessageStr.toLowerCase().contains('video call') ||
                          lastMessageStr.toLowerCase().contains('audio call')) ...[
                        Icon(
                          lastMessageStr == 'Attachment'
                              ? Icons.attachment_rounded
                              : lastMessageStr.toLowerCase().contains('video call')
                                  ? Icons.videocam_rounded
                                  : Icons.call_rounded,
                          size: 14,
                          color: lastMessageStr.startsWith('Missed')
                              ? Colors.red
                              : (hasUnread ? AppColors.textPrimary : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          lastMessageStr,
                          style: TextStyle(
                            fontSize: 15,
                            color: isTyping
                                ? AppColors.primary
                                : (lastMessageStr.startsWith('Missed')
                                    ? Colors.red
                                    : (conversation == null
                                        ? AppColors.textSecondary
                                        : (hasUnread
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary))),
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
      ).animate().fadeIn(delay: widget.delay, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
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
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: _imageUrl != null
                ? Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
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
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          widget.profile.name.isNotEmpty
              ? widget.profile.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
