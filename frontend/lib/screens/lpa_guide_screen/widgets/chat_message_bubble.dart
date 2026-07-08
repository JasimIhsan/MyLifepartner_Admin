import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import '../lpa_guide_screen.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.sender == MessageSender.assistant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssistant) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                if (message.type == MessageType.text)
                  _buildTextBubble(message, isAssistant)
                else if (message.type == MessageType.thinking)
                  _buildThinkingBubble(message.text),
              ],
            ),
          ),
          if (!isAssistant) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(
    String text, {
    required TextStyle style,
    required TextStyle boldStyle,
  }) {
    final parts = text.split('**');
    if (parts.length <= 1) {
      return Text(text, style: style);
    }

    final List<TextSpan> spans = [];
    for (var i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(TextSpan(text: parts[i], style: isBold ? boldStyle : style));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTextBubble(ChatMessage message, bool isAssistant) {
    final List<String> bullets = message.data is List<String>
        ? message.data as List<String>
        : [];

    final baseStyle = TextStyle(
      fontSize: 14,
      color: isAssistant ? AppColors.textPrimary : Colors.white,
      height: 1.45,
    );
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAssistant ? Colors.grey.shade100 : AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isAssistant ? 4 : 16),
          bottomRight: Radius.circular(isAssistant ? 16 : 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormattedText(
            message.text,
            style: baseStyle,
            boldStyle: boldStyle,
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...bullets.map((bullet) {
              final bulletBaseStyle = TextStyle(
                fontSize: 13.5,
                color: isAssistant
                    ? AppColors.textSecondary
                    : Colors.white.withValues(alpha: 0.9),
                height: 1.35,
              );
              final bulletBoldStyle = bulletBaseStyle.copyWith(
                fontWeight: FontWeight.bold,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, right: 8.0),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isAssistant
                              ? AppColors.primary
                              : Colors.white70,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildFormattedText(
                        bullet,
                        style: bulletBaseStyle,
                        boldStyle: bulletBoldStyle,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
