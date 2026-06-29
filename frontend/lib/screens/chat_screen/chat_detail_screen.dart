import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/chat_message.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/providers/call_provider.dart';
import 'package:mylifepartner/providers/chat_provider.dart';
import 'package:mylifepartner/providers/subscription_provider.dart';
import 'package:mylifepartner/screens/chat_screen/outgoing_call_screen.dart';
import 'package:mylifepartner/services/chat_service.dart';
import 'package:mylifepartner/widgets/feature_exhausted_modal.dart';
import 'package:mylifepartner/widgets/inline_video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import 'package:mylifepartner/screens/chat_screen/widgets/chat_detail_app_bar.dart';
import 'package:mylifepartner/screens/chat_screen/widgets/chat_message_bubble.dart';
import 'package:mylifepartner/screens/chat_screen/widgets/chat_input_area.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _chatProvider = context.read<ChatProvider>();
    _initChat();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chatProvider = context.read<ChatProvider>();
      chatProvider.setActiveUserId(widget.profile.userId);
      chatProvider.clearUnreadNudge(widget.profile.userId);

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
          showDialog(
            context: context,
            builder: (_) =>
                const FeatureExhaustedModal(featureType: 'Chat Messages'),
          );
        } else {
          String errorMsg = 'Failed to send message. Try again.';
          if (e is DioException && e.response?.data != null && e.response?.data is Map) {
            errorMsg = e.response?.data['message'] ?? errorMsg;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
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
          showDialog(
            context: context,
            builder: (_) =>
                const FeatureExhaustedModal(featureType: 'Chat Messages'),
          );
        } else {
          String errorMsg = 'Failed to send media msg.';
          if (e is DioException && e.response?.data != null && e.response?.data is Map) {
            errorMsg = e.response?.data['message'] ?? errorMsg;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
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
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAttachmentOption(
                        icon: Icons.image_rounded,
                        label: 'Photo',
                        color: Colors.purple.shade400,
                        onTap: () async {
                          Navigator.pop(context);
                          final picker = ImagePicker();
                          final file = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (file != null) {
                            _previewAndSendMedia(file.path, 'IMAGE');
                          }
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.video_collection_rounded,
                        label: 'Video',
                        color: Colors.orange.shade400,
                        onTap: () async {
                          Navigator.pop(context);
                          final picker = ImagePicker();
                          final file = await picker.pickVideo(
                            source: ImageSource.gallery,
                          );
                          if (file != null) {
                            _previewAndSendMedia(file.path, 'VIDEO');
                          }
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        color: Colors.blue.shade400,
                        onTap: () async {
                          Navigator.pop(context);
                          final picker = ImagePicker();
                          final file = await picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (file != null) {
                            _previewAndSendMedia(file.path, 'IMAGE');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _previewAndSendMedia(String path, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: type == 'IMAGE'
                        ? Image.file(File(path), fit: BoxFit.contain)
                        : InlineVideoPlayer(source: path, isMe: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _sendMediaMsg(path, type);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _startCall({required bool isVideo}) async {
    // Check with the backend directly if call is allowed
    try {
      await ChatApiService.checkCallAccess(type: isVideo ? 'video' : 'audio');
    } catch (e) {
      if (mounted) {
        if (e is DioException && e.response?.statusCode == 402) {
          showDialog(
            context: context,
            builder: (_) => FeatureExhaustedModal(
              featureType: isVideo ? 'Video Call' : 'Audio Call',
            ),
          );
        } else {
          String errorMsg = 'Failed to verify call access. Try again.';
          if (e is DioException && e.response?.data != null && e.response?.data is Map) {
            errorMsg = e.response?.data['message'] ?? errorMsg;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
            ),
          );
        }
      }
      return;
    }

    if (!mounted) return;

    final callProvider = context.read<CallProvider>();
    final otherUserId = widget.profile.userId.toString();

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatDetailAppBar(
        profileName: widget.profile.name,
        profileImageUrl: _profileImageUrl,
        onAudioCall: () => _startCall(isVideo: false),
        onVideoCall: () => _startCall(isVideo: true),
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

                  if (messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.waving_hand_rounded,
                            color: Colors.orangeAccent,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Say hi!',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Don\'t be shy, start the conversation.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Render from bottom up
                    padding: const EdgeInsets.only(
                      top: 16,
                      bottom: 24,
                      left: 16,
                      right: 16,
                    ),
                    itemCount: messages.length +
                        (provider.isLoadingMore(_conversationId!) ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
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

                      final msg = messages[messages.length - 1 - index];
                      final isMe = msg.senderId == widget.currentUserId;

                      // Calculate if we need extra spacing (e.g., messages are far apart in time or different sender)
                      bool needsMoreSpace = false;
                      if (index < messages.length - 1) {
                        final nextMsgToRender =
                            messages[messages.length -
                                1 -
                                (index +
                                    1)]; // actually older msg visually above it
                        if (nextMsgToRender.senderId != msg.senderId) {
                          needsMoreSpace = true;
                        }
                      } else {
                        needsMoreSpace = true; // First message visually (topmost)
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
