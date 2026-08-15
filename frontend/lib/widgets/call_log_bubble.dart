import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/chat_message.dart';

class CallLogBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;

  const CallLogBubble({super.key, required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    String callType = 'audio';
    String status = 'completed';
    int duration = 0;

    try {
      final payload = jsonDecode(msg.content);
      callType = payload['callType'] ?? 'audio';
      status = payload['status'] ?? 'completed';
      duration = payload['duration'] ?? 0;
    } catch (_) {}

    final format = DateFormat('hh:mm a');
    final timeStr = format.format(msg.createdAt.toLocal());

    IconData icon;
    String title;
    String subtitle;
    Color iconColor;

    bool isVideo = callType == 'video';

    if (status == 'completed') {
      icon = isVideo ? Icons.videocam_rounded : Icons.call_rounded;
      title = '${isVideo ? 'Video' : 'Voice'} Call';
      subtitle = _formatDuration(duration);
      iconColor = Theme.of(context).primaryColor;
    } else if (status == 'declined') {
      icon = isVideo
          ? Icons.videocam_off_rounded
          : Icons.phone_disabled_rounded;
      title = 'Declined Call';
      subtitle = isVideo ? 'Video' : 'Voice';
      iconColor = const Color(0xFFFF3B30);
    } else {
      icon = isVideo
          ? Icons.missed_video_call_rounded
          : Icons.call_missed_rounded;
      title = 'Missed Call';
      subtitle = isVideo ? 'Video' : 'Voice';
      iconColor = const Color(0xFFFF3B30);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: isMe
                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                : Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                timeStr,
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
