import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/chat_message.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/providers/call_provider.dart';
import 'package:mylifepartner/providers/chat_provider.dart';
import 'package:mylifepartner/providers/subscription_provider.dart';
import 'package:mylifepartner/screens/chat_screen/outgoing_call_screen.dart';
import 'package:mylifepartner/screens/chat_screen/widgets/attachment_bottom_sheet.dart';
import 'package:mylifepartner/screens/chat_screen/widgets/chat_detail_app_bar.dart';
import 'package:mylifepartner/screens/chat_screen/widgets/chat_empty_state.dart';
import 'package:mylifepartner/screens/chat_screen/widgets/chat_input_area.dart';
import 'package:mylifepartner/screens/chat_screen/widgets/chat_message_bubble.dart';
import 'package:mylifepartner/screens/chat_screen/widgets/media_preview_screen.dart';
import 'package:mylifepartner/services/chat_service.dart';
import 'package:mylifepartner/widgets/bottomsheet/feature_exhausted_modal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

class ChatDetailScreen extends StatefulWidget {
  final MatchRecommendation profile;
  final int currentUserId;

  const ChatDetailScreen({
    super.key,
    required this.profile,
    required this.currentUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _conversationId;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isRecordingFinished = false;
  String? _recordingPath;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  late final ChatProvider _chatProvider;
  Timer? _typingDebounce;
  Timer? _typingHeartbeatTimer;
  bool _isCurrentlyTyping = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _msgController.addListener(_onTextChanged);
    _chatProvider = context.read<ChatProvider>();
    _initChat();
  }

  void _onTextChanged() {
    final text = _msgController.text.trim();
    final isTyping = text.isNotEmpty;

    if (isTyping != _isCurrentlyTyping) {
      _isCurrentlyTyping = isTyping;
      _chatProvider.sendTypingStatus(widget.profile.userId, _isCurrentlyTyping);

      if (_isCurrentlyTyping) {
        _typingHeartbeatTimer?.cancel();
        _typingHeartbeatTimer = Timer.periodic(const Duration(seconds: 5), (
          timer,
        ) {
          if (mounted && _isCurrentlyTyping) {
            _chatProvider.sendTypingStatus(widget.profile.userId, true);
          }
        });
      } else {
        _typingHeartbeatTimer?.cancel();
        _typingHeartbeatTimer = null;
      }
    }

    if (isTyping) {
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        if (mounted && _isCurrentlyTyping) {
          setState(() {
            _isCurrentlyTyping = false;
          });
          _typingHeartbeatTimer?.cancel();
          _typingHeartbeatTimer = null;
          _chatProvider.sendTypingStatus(widget.profile.userId, false);
        }
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (_conversationId != null) {
        if (_chatProvider.hasMoreMessages(_conversationId!) &&
            !_chatProvider.isLoadingMore(_conversationId!)) {
          _chatProvider.loadMessages(
            _conversationId!,
            page: _chatProvider.currentPage(_conversationId!) + 1,
          );
        }
      }
    }
  }

  void _initChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final chatProvider = context.read<ChatProvider>();
      chatProvider.setCurrentUserId(widget.currentUserId);
      await chatProvider.ensureZegoLogin(widget.currentUserId);

      if (!mounted) return;
      chatProvider.setActiveUserId(widget.profile.userId);
      chatProvider.clearUnreadNudge(widget.profile.userId);
      chatProvider.subscribeToUserStatus(widget.profile.userId);

      // Ensure features are loaded for limit checks
      context.read<SubscriptionProvider>().fetchMySubscription();

      // Find the existing conversation if it exists
      final existingConvo = chatProvider.conversations.where((c) {
        return c.otherUserId == widget.profile.userId;
      }).firstOrNull;

      if (existingConvo != null) {
        setState(() {
          _conversationId = existingConvo.id;
        });
        chatProvider.loadMessages(existingConvo.id);
      }
    });
  }

  @override
  void dispose() {
    _chatProvider.setActiveUserId(null);
    _chatProvider.unsubscribeFromUserStatus(widget.profile.userId);
    if (_isCurrentlyTyping) {
      _chatProvider.sendTypingStatus(widget.profile.userId, false);
    }
    _typingDebounce?.cancel();
    _typingHeartbeatTimer?.cancel();
    _msgController.removeListener(_onTextChanged);
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    _typingDebounce?.cancel();
    _typingHeartbeatTimer?.cancel();
    _typingHeartbeatTimer = null;
    if (_isCurrentlyTyping) {
      _isCurrentlyTyping = false;
      _chatProvider.sendTypingStatus(widget.profile.userId, false);
    }

    final chatProvider = context.read<ChatProvider>();
    final convoId = context
        .read<ChatProvider>()
        .conversations
        .where((c) => c.otherUserId == widget.profile.userId)
        .firstOrNull
        ?.id;

    try {
      final message = await chatProvider.sendMessage(
        receiverId: widget.profile.userId,
        content: text,
        conversationId: convoId ?? _conversationId,
      );

      if (mounted && _conversationId == null && message != null) {
        setState(() {
          _conversationId = message.conversationId;
        });
      }

      _initChat(); // Re-fetch to update convo id if it was newly created
      if (mounted) context.read<SubscriptionProvider>().fetchMySubscription();

      // Smooth scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        if (e is DioException && e.response?.statusCode == 402) {
          FeatureExhaustedModal.show(context, featureType: 'Chat Messages');
        } else {
          String errorMsg = 'Failed to send message. Try again.';
          if (e is DioException &&
              e.response?.data != null &&
              e.response?.data is Map) {
            errorMsg = e.response?.data['message'] ?? errorMsg;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      }
    }
  }

  void _sendMediaMsg(String path, String messageType, {int? duration}) async {
    final chatProvider = context.read<ChatProvider>();
    try {
      final message = await chatProvider.sendMediaMessage(
        receiverId: widget.profile.userId,
        filePath: path,
        messageType: messageType,
        audioDuration: duration,
      );

      if (mounted && _conversationId == null && message != null) {
        setState(() {
          _conversationId = message.conversationId;
        });
      }

      if (mounted) context.read<SubscriptionProvider>().fetchMySubscription();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        if (e is DioException && e.response?.statusCode == 402) {
          FeatureExhaustedModal.show(context, featureType: 'Chat Messages');
        } else {
          String errorMsg = 'Failed to send media msg.';
          if (e is DioException &&
              e.response?.data != null &&
              e.response?.data is Map) {
            errorMsg = e.response?.data['message'] ?? errorMsg;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      }
    }
  }

  Future<void> _startRecordingUI() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filename =
            'audio_msg_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recordingPath = '${dir.path}/$filename';
        _recordingStartTime = DateTime.now();
        _recordingDuration = Duration.zero;

        await _audioRecorder.start(const RecordConfig(), path: _recordingPath!);

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordingDuration = DateTime.now().difference(
                _recordingStartTime!,
              );
            });
          }
        });

        if (mounted) {
          setState(() {
            _isRecording = true;
            _isRecordingFinished = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
      }
    }
  }

  void _stopAndPreviewRecording() async {
    final path = await _audioRecorder.stop();
    _recordingTimer?.cancel();
    _recordingTimer = null;

    if (mounted) {
      setState(() {
        _isRecording = false;
        if (path != null) {
          _recordingPath = path;
          _isRecordingFinished = true;
        } else {
          _cancelRecording();
        }
      });
    }
  }

  void _cancelRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
    }
    _recordingTimer?.cancel();
    _recordingTimer = null;
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) await file.delete();
    }
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isRecordingFinished = false;
        _recordingPath = null;
        _recordingDuration = Duration.zero;
      });
    }
  }

  void _sendRecordedAudio() {
    if (_recordingPath != null && _recordingDuration.inSeconds > 0) {
      _sendMediaMsg(
        _recordingPath!,
        'AUDIO',
        duration: _recordingDuration.inSeconds,
      );
    }
    if (mounted) {
      setState(() {
        _isRecordingFinished = false;
        _recordingPath = null;
        _recordingDuration = Duration.zero;
      });
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AttachmentBottomSheet(
          onMediaSelected: (path, type) {
            _previewAndSendMedia(path, type);
          },
        );
      },
    );
  }

  void _previewAndSendMedia(String path, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaPreviewScreen(
          path: path,
          type: type,
          onSend: () => _sendMediaMsg(path, type),
        ),
      ),
    );
  }

  void _startCall({required bool isVideo}) async {
    final otherUserId = widget.profile.userId.toString();
    final callType = isVideo ? 'video' : 'audio';

    // Check with the backend directly if caller has access
    try {
      await ChatApiService.checkCallAccess(type: callType);
    } catch (e) {
      if (mounted) {
        if (e is DioException && e.response?.statusCode == 402) {
          FeatureExhaustedModal.show(
            context,
            featureType: isVideo ? 'Video Call' : 'Audio Call',
          );
        } else {
          String errorMsg = 'Failed to verify call access. Try again.';
          if (e is DioException &&
              e.response?.data != null &&
              e.response?.data is Map) {
            errorMsg = e.response?.data['message'] ?? errorMsg;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      }
      return;
    }

    if (!mounted) return;

    // Check if recipient has access/allowance
    try {
      await ChatApiService.checkCallAccess(
        type: callType,
        targetUserId: otherUserId,
      );
    } catch (e) {
      if (mounted) {
        String errorMsg = 'The recipient is temporarily unavailable for calls.';
        if (e is DioException &&
            e.response?.data != null &&
            e.response?.data is Map) {
          errorMsg = e.response?.data['message'] ?? errorMsg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final callProvider = context.read<CallProvider>();

    // Send invitation signal and track outgoing call state
    callProvider.initiateCall(
      otherUserId: otherUserId,
      otherUserName: widget.profile.name,
      calleeAvatar: _profileImageUrl,
      isVideo: isVideo,
    );

    // Navigate to the "Calling..." screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutgoingCallScreen(
          calleeName: widget.profile.name,
          calleeAvatar: _profileImageUrl,
          isVideoCall: isVideo,
        ),
      ),
    );
  }

  String? get _profileImageUrl {
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
    final isOnline = chatProvider.isUserOnline(widget.profile.userId);
    final isTyping = chatProvider.isUserTyping(widget.profile.userId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatDetailAppBar(
        profileName: widget.profile.name,
        profileImageUrl: _profileImageUrl,
        onAudioCall: () => _startCall(isVideo: false),
        onVideoCall: () => _startCall(isVideo: true),
        isOnline: isOnline,
        isTyping: isTyping,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, child) {
                  final messages = _conversationId != null
                      ? provider.getMessages(_conversationId!)
                      : <ChatMessage>[];

                  if (messages.isEmpty && !isTyping) {
                    return const ChatEmptyState();
                  }

                  final showTypingIndicator = isTyping;
                  final count =
                      messages.length +
                      (provider.isLoadingMore(_conversationId!) ? 1 : 0) +
                      (showTypingIndicator ? 1 : 0);

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Render from bottom up
                    padding: const EdgeInsets.only(
                      top: 16,
                      bottom: 24,
                      left: 16,
                      right: 16,
                    ),
                    itemCount: count,
                    itemBuilder: (context, index) {
                      if (showTypingIndicator && index == 0) {
                        return const BouncingDotsIndicator();
                      }

                      final msgIndex = showTypingIndicator ? index - 1 : index;

                      if (msgIndex == messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      }

                      final msg = messages[messages.length - 1 - msgIndex];
                      final isMe = msg.senderId == widget.currentUserId;

                      // Calculate if we need extra spacing (e.g., messages are far apart in time or different sender)
                      bool needsMoreSpace = false;
                      if (msgIndex < messages.length - 1) {
                        final nextMsgToRender =
                            messages[messages.length -
                                1 -
                                (msgIndex +
                                    1)]; // actually older msg visually above it
                        if (nextMsgToRender.senderId != msg.senderId) {
                          needsMoreSpace = true;
                        }
                      } else {
                        needsMoreSpace =
                            true; // First message visually (topmost)
                      }

                      return Padding(
                        padding: EdgeInsets.only(top: needsMoreSpace ? 16 : 4),
                        child: ChatMessageBubble(msg: msg, isMe: isMe),
                      );
                    },
                  );
                },
              ),
            ),
            ChatInputArea(
              isRecording: _isRecording,
              isRecordingFinished: _isRecordingFinished,
              msgController: _msgController,
              recordingPath: _recordingPath,
              recordingDuration: _recordingDuration,
              onCancelRecording: _cancelRecording,
              onShowAttachmentOptions: _showAttachmentOptions,
              onSendMessage: _sendMessage,
              onSendRecordedAudio: _sendRecordedAudio,
              onStartRecording: _startRecordingUI,
              onStopRecording: _stopAndPreviewRecording,
            ),
          ],
        ),
      ),
    );
  }
}

class BouncingDotsIndicator extends StatefulWidget {
  const BouncingDotsIndicator({super.key});

  @override
  State<BouncingDotsIndicator> createState() => _BouncingDotsIndicatorState();
}

class _BouncingDotsIndicatorState extends State<BouncingDotsIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: -8,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      _controllers[i].repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFECECEC),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animations[index].value),
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF9E9E9E),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
