import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:life_partner_again/core/app_colors.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String source;
  final bool isMe;

  const InlineVideoPlayer({
    super.key,
    required this.source,
    required this.isMe,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.source.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.source))
        : VideoPlayerController.file(File(widget.source));

    _controller.initialize().then((_) {
      if (mounted) setState(() => _isInit = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_collection_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 240,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
