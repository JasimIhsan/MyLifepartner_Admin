import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mylifepartner/core/app_colors.dart';

class InlineAudioPlayer extends StatefulWidget {
  final String source;
  final bool isMe;

  const InlineAudioPlayer({super.key, required this.source, required this.isMe});

  @override
  State<InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<InlineAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudio();
  }

  void _setupAudio() {
    final source = widget.source.startsWith('http')
        ? UrlSource(widget.source)
        : DeviceFileSource(widget.source);
    _audioPlayer.setSource(source);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isMe ? Colors.white : AppColors.primary;
    final bgColor = widget.isMe ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1);

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isPlaying) {
                _audioPlayer.pause();
              } else {
                _audioPlayer.resume();
              }
            },
            child: CircleAvatar(
              backgroundColor: bgColor,
              radius: 20,
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: fgColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: fgColor,
                    inactiveTrackColor: bgColor,
                    thumbColor: fgColor,
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds.toDouble(),
                    value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()),
                    onChanged: (val) {
                      _audioPlayer.seek(Duration(milliseconds: val.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(color: fgColor.withValues(alpha: 0.8), fontSize: 10),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(color: fgColor.withValues(alpha: 0.8), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
