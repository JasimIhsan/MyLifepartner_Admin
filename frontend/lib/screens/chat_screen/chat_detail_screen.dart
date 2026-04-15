import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/chat_message.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/providers/call_provider.dart';
import 'package:mylifepartner/providers/chat_provider.dart';
import 'package:mylifepartner/screens/chat_screen/call_screen.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chatProvider = context.read<ChatProvider>();
      chatProvider.setActiveUserId(widget.profile.id);

      // Find the existing conversation if it exists
      final existingConvo = chatProvider.conversations.where((c) {
        return (c.userOneId == widget.currentUserId &&
                c.userTwoId == widget.profile.id) ||
            (c.userOneId == widget.profile.id &&
                c.userTwoId == widget.currentUserId);
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
    if (mounted) {
      context.read<ChatProvider>().setActiveUserId(null);
    }
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    final chatProvider = context.read<ChatProvider>();
    try {
      print(" the id is ${widget.profile.id}");
      await chatProvider.sendMessage(
        receiverId: widget.profile.id,
        content: text,
        conversationId: _conversationId,
      );
      _initChat(); // Re-fetch to update convo id if it was newly created
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Try again.')),
        );
      }
    }
  }

  void _startCall({required bool isVideo}) {
    final callProvider = context.read<CallProvider>();
    final otherUserId = widget.profile.id.toString();

    // Send invitation signal to the other user
    callProvider.initiateCall(otherUserId: otherUserId, isVideo: isVideo);

    // Navigate caller to the call screen immediately
    CallScreen.startCall(
      context,
      currentUserId: widget.currentUserId.toString(),
      currentUserName: 'User ${widget.currentUserId}',
      otherUserId: otherUserId,
      isVideoCall: isVideo,
    );
  }

  String? get _profileImageUrl {
    final primary = widget.profile.images.where((img) => img.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    if (widget.profile.images.isNotEmpty)
      return widget.profile.images.first.imageUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
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
                      child: Text(
                        'Say hi!',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Render from bottom up
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      // Reverse the index mapping since the list is oldest-first,
                      // and we want newest (last in list) at the bottom (index 0 of ListView).
                      final msg = messages[messages.length - 1 - index];
                      final isMe = msg.senderId == widget.currentUserId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.divider,
            backgroundImage: _profileImageUrl != null
                ? NetworkImage(_profileImageUrl!)
                : null,
            child: _profileImageUrl == null
                ? const Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 20,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.profile.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_rounded, color: AppColors.primary),
          onPressed: () => _startCall(isVideo: false),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_rounded, color: AppColors.primary),
          onPressed: () => _startCall(isVideo: true),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final format = DateFormat('hh:mm a');
    final timeStr = format.format(msg.createdAt.toLocal());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: isMe ? Colors.white70 : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _msgController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
