import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/chat_message.dart';
import 'package:mylifepartner/providers/chat_provider.dart';
import 'package:mylifepartner/widgets/call_log_bubble.dart';
import 'package:mylifepartner/widgets/inline_audio_player.dart';
import 'package:mylifepartner/widgets/inline_video_player.dart';
import 'package:provider/provider.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;

  const ChatMessageBubble({super.key, required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (msg.messageType == 'CALL_LOG') {
      return CallLogBubble(msg: msg, isMe: isMe);
    }

    final format = DateFormat('hh:mm a');
    final timeStr = format.format(msg.createdAt.toLocal());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFFE82B2B)],
                )
              : null,
          color: isMe ? null : AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (msg.messageType == 'IMAGE' || msg.messageType == 'VIDEO')
              _buildDownloadableMedia(msg, isMe, context)
            else if (msg.messageType == 'AUDIO')
              InlineAudioPlayer(source: msg.content, isMe: isMe)
            else
              Text(
                msg.content,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // if (isMe) ...[
                //   const SizedBox(width: 4),
                //   Icon(
                //     Icons
                //         .done_all_rounded, // or any read receipt icon you prefer
                //     size: 14,
                //     color: Colors.white.withValues(alpha: 0.7),
                //   ),
                // ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadableMedia(
    ChatMessage msg,
    bool isMe,
    BuildContext context,
  ) {
    final chatProvider = context.read<ChatProvider>();
    final isDownloaded = chatProvider.isMediaDownloaded(msg.id);

    final placeholder = Container(
      key: const ValueKey('placeholder'),
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            msg.messageType == 'IMAGE'
                ? Icons.image_rounded
                : Icons.video_collection_rounded,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          isDownloaded
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                )
              : GestureDetector(
                  onTap: () => chatProvider.markMediaDownloaded(msg.id),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Download',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );

    Widget content;
    if (!isMe && !isDownloaded) {
      content = placeholder;
    } else {
      if (msg.messageType == 'IMAGE') {
        content = msg.content.startsWith('http')
            ? Image.network(
                msg.content,
                key: ValueKey(msg.content),
                width: 240,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return placeholder;
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return placeholder;
                },
              )
            : Image.file(
                File(msg.content),
                key: ValueKey(msg.content),
                width: 240,
                fit: BoxFit.cover,
              );
      } else {
        content = InlineVideoPlayer(
          source: msg.content,
          isMe: isMe,
          key: ValueKey(msg.content),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: content,
        ),
      ),
    );
  }
}
