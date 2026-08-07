import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class InlineAudioPlayer extends StatefulWidget {
  final String source;
  final bool isMe;
  final double? width;

  const InlineAudioPlayer({
    super.key,
    required this.source,
    required this.isMe,
    this.width = 200,
  });

  @override
  State<InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<InlineAudioPlayer> {
  static _InlineAudioPlayerState? _activePlayer;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _playOnReady = false;
  bool _isDraggingSlider = false;
  bool _wasPlayingBeforeDrag = false;
  double _dragValue = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Source? _audioSource;

  @override
  void initState() {
    super.initState();
    _configureAudioContext();
    _setupAudio();
  }

  @override
  void didUpdateWidget(InlineAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      if (_activePlayer == this) _activePlayer = null;
      _audioPlayer.stop();
      _setupAudio();
    }
  }

  void _configureAudioContext() {
    try {
      AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.defaultToSpeaker},
          ),
          android: const AudioContextAndroid(
            stayAwake: true,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[InlineAudioPlayer] Error configuring audio context: $e');
    }
  }

  Future<void> _setupAudio() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    String finalSource = widget.source;

    if (finalSource.startsWith('http')) {
      try {
        final dir = await getTemporaryDirectory();
        final safeHash = finalSource.hashCode.abs().toString();
        final file = File('${dir.path}/audio_cache_$safeHash.m4a');

        if (await file.exists() && (await file.length()) > 0) {
          finalSource = file.path;
        } else {
          await Dio().download(
            widget.source,
            file.path,
            options: Options(
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
            ),
          );
          if (await file.exists() && (await file.length()) > 0) {
            finalSource = file.path;
          }
        }
      } catch (e) {
        debugPrint(
          '[InlineAudioPlayer] Audio download failed, fallback to url: $e',
        );
      }
    }

    _audioSource = finalSource.startsWith('http')
        ? UrlSource(finalSource)
        : DeviceFileSource(finalSource);

    try {
      await _audioPlayer.setSource(_audioSource!);

      final dur = await _audioPlayer.getDuration();
      if (dur != null && mounted) {
        setState(() {
          _duration = dur;
        });
      }

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
        if (mounted && !_isDraggingSlider) {
          setState(() => _position = newPosition);
        }
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (_playOnReady) {
          _playOnReady = false;
          _togglePlay();
        }
      }
    } catch (e) {
      debugPrint('[InlineAudioPlayer] _setupAudio error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlay() async {
    if (_isLoading) {
      setState(() {
        _playOnReady = !_playOnReady;
      });
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_activePlayer != null && _activePlayer != this) {
          await _activePlayer!._audioPlayer.pause();
          if (_activePlayer!.mounted) {
            _activePlayer!.setState(() {
              _activePlayer!._isPlaying = false;
            });
          }
        }
        _activePlayer = this;

        if (_position >= _duration && _duration > Duration.zero) {
          await _audioPlayer.seek(Duration.zero);
        }
        await _audioPlayer.resume();
      }
    } catch (e) {
      debugPrint('[InlineAudioPlayer] _togglePlay error: $e');
      if (_audioSource != null) {
        await _audioPlayer.play(_audioSource!);
      }
    }
  }

  @override
  void dispose() {
    if (_activePlayer == this) _activePlayer = null;
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isMe ? Colors.white : Theme.of(context).primaryColor;
    final bgColor = widget.isMe
        ? Colors.white.withValues(alpha: 0.2)
        : Theme.of(context).primaryColor.withValues(alpha: 0.1);

    final maxVal = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    
    double currentVal = _isDraggingSlider
        ? _dragValue
        : _position.inMilliseconds.toDouble();
        
    if (_duration.inMilliseconds == 0) {
      currentVal = 0.0;
    } else {
      currentVal = currentVal.clamp(0.0, maxVal);
    }

    return Container(
      width: widget.width,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: CircleAvatar(
              backgroundColor: bgColor,
              radius: 20,
              child: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fgColor,
                      ),
                    )
                  : Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
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
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: fgColor,
                    inactiveTrackColor: bgColor,
                    thumbColor: fgColor,
                  ),
                  child: Slider(
                    min: 0,
                    max: maxVal,
                    value: currentVal,
                    onChangeStart: (val) async {
                      _wasPlayingBeforeDrag = _isPlaying;
                      if (_isPlaying) {
                        await _audioPlayer.pause();
                      }
                      setState(() {
                        _isDraggingSlider = true;
                        _dragValue = val;
                      });
                    },
                    onChanged: (val) {
                      setState(() {
                        _dragValue = val;
                      });
                    },
                    onChangeEnd: (val) async {
                      await _audioPlayer.seek(
                        Duration(milliseconds: val.toInt()),
                      );
                      if (mounted) {
                        setState(() {
                          _position = Duration(milliseconds: val.toInt());
                          _isDraggingSlider = false;
                        });
                        if (_wasPlayingBeforeDrag) {
                          await _audioPlayer.resume();
                        }
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(
                          _isDraggingSlider
                              ? Duration(milliseconds: _dragValue.toInt())
                              : _position,
                        ),
                        style: TextStyle(
                          color: fgColor.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          color: fgColor.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
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
