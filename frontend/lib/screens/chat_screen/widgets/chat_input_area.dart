import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/chat_screen/widgets/inline_audio_player.dart';

class ChatInputArea extends StatelessWidget {
  final bool isRecording;
  final bool isRecordingFinished;
  final TextEditingController msgController;
  final String? recordingPath;
  final Duration recordingDuration;
  final VoidCallback onCancelRecording;
  final VoidCallback onShowAttachmentOptions;
  final VoidCallback onSendMessage;
  final VoidCallback onSendRecordedAudio;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onStopAndSendRecording;

  const ChatInputArea({
    super.key,
    required this.isRecording,
    required this.isRecordingFinished,
    required this.msgController,
    this.recordingPath,
    required this.recordingDuration,
    required this.onCancelRecording,
    required this.onShowAttachmentOptions,
    required this.onSendMessage,
    required this.onSendRecordedAudio,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onStopAndSendRecording,
  });

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 20, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isRecording || isRecordingFinished)
            IconButton(
              onPressed: onCancelRecording,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            IconButton(
              onPressed: onShowAttachmentOptions,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 24,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isRecording || isRecordingFinished
                  ? _buildRecordingMiddle()
                  : _buildTextMiddle(),
            ),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: msgController,
            builder: (context, value, child) {
              final isTextEmpty = value.text.trim().isEmpty;
              return GestureDetector(
                onTap: () {
                  if (isRecordingFinished) {
                    onSendRecordedAudio();
                  } else if (isRecording) {
                    onStopRecording();
                  } else if (!isTextEmpty) {
                    onSendMessage();
                  } else {
                    onStartRecording();
                  }
                },
                onLongPressStart:
                    (isTextEmpty && !isRecording && !isRecordingFinished)
                    ? (_) => onStartRecording()
                    : null,
                onLongPressEnd: isRecording
                    ? (_) => onStopAndSendRecording()
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: isRecording ? 52 : 44,
                  width: isRecording ? 52 : 44,
                  decoration: BoxDecoration(
                    color: isRecording ? Colors.redAccent : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isRecording
                            ? Colors.redAccent.withValues(alpha: 0.3)
                            : const Color(0x33FF3F3F),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isRecordingFinished
                        ? Icons.send_rounded
                        : (isRecording
                              ? Icons.stop_rounded
                              : (isTextEmpty
                                    ? Icons.mic_rounded
                                    : Icons.arrow_upward_rounded)),
                    color: Colors.white,
                    size: isRecording ? 28 : 24,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingMiddle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: isRecording
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(duration: 500.ms),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(recordingDuration),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            )
          : InlineAudioPlayer(
              source: recordingPath!,
              isMe: false,
              width: double.infinity,
            ),
    );
  }

  Widget _buildTextMiddle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: msgController,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSendMessage(),
            maxLines: 4,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Message...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
