import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mylifepartner/models/chat_message.dart';
import 'package:mylifepartner/services/chat_service.dart';
import 'package:mylifepartner/services/zego_service.dart';
import 'package:zego_zim/zego_zim.dart';

class ChatProvider extends ChangeNotifier {
  final Map<int, List<ChatMessage>> _messagesByConversation = {};
  final Map<int, int> _currentPageByConversation = {};
  final Map<int, bool> _hasMoreByConversation = {};
  final Map<int, bool> _isLoadingMoreByConversation = {};
  List<ChatConversation> _conversations = [];
  bool _isLoading = false;
  int? _currentUserId;
  StreamSubscription? _zimSubscription;

  int? _activeUserId;
  final Set<int> _unreadUserIds = {};
  final Set<int> _downloadedMedia = {};

  List<ChatConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;

  bool hasMoreMessages(int conversationId) => _hasMoreByConversation[conversationId] ?? true;
  bool isLoadingMore(int conversationId) => _isLoadingMoreByConversation[conversationId] ?? false;
  int currentPage(int conversationId) => _currentPageByConversation[conversationId] ?? 1;

  int? get activeUserId => _activeUserId;
  bool hasUnreadNudge(int userId) => _unreadUserIds.contains(userId);

  bool isMediaDownloaded(int messageId) => _downloadedMedia.contains(messageId);
  void markMediaDownloaded(int messageId) {
    _downloadedMedia.add(messageId);
    notifyListeners();
  }

  List<ChatMessage> getMessages(int conversationId) {
    return _messagesByConversation[conversationId] ?? [];
  }

  void setCurrentUserId(int userId) {
    _currentUserId = userId;
  }

  void setActiveUserId(int? userId) {
    _activeUserId = userId;
    if (userId != null) {
      clearUnreadNudge(userId);
    }
  }

  void clearUnreadNudge(int userId) {
    if (_unreadUserIds.remove(userId)) {
      notifyListeners();
    }
  }

  /// Start listening for incoming ZIM messages
  void startListening() {
    _zimSubscription?.cancel();
    _zimSubscription = ZegoService.instance.onMessageReceived.listen((msg) {
      _handleIncomingMessage(msg);
    });
  }

  void _handleIncomingMessage(ZegoZIMMessage msg) {
    // Skip JSON call-signaling messages — handled by CallProvider.
    if (msg.content.startsWith('{')) return;

    // Do NOT persist to backend here, the sender is responsible for that.
    // Instead, we just show it up locally or show an unread nudge.
    final senderId = int.tryParse(msg.fromUserId);
    if (senderId == null || _currentUserId == null) return;

    // Vibrate the phone
    HapticFeedback.vibrate();

    final conversationIndex = _conversations.indexWhere(
      (c) => c.otherUserId == senderId,
    );
    ChatConversation? conversation;
    if (conversationIndex != -1) {
      conversation = _conversations[conversationIndex];
    }

    if (_activeUserId == senderId) {
      // Append to local state if active
      if (conversation != null) {
        final message = ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch,
          conversationId: conversation.id,
          senderId: senderId,
          content: msg.content,
          messageType: msg.messageType,
          createdAt: DateTime.now(),
        );

        _messagesByConversation[conversation.id] ??= [];
        _messagesByConversation[conversation.id]!.add(message);
      }
    } else {
      // They are not in this chat interface actively, show nudge
      _unreadUserIds.add(senderId);
    }

    // Refresh conversations to pick up the new message silently
    notifyListeners();
    loadConversations(showLoading: false);
  }

  /// Load all conversations
  Future<void> loadConversations({bool showLoading = true}) async {
    if (_currentUserId == null) return;

    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final data = await ChatApiService.getConversations();
      _conversations = data
          .map(
            (json) => ChatConversation.fromJson(
              json as Map<String, dynamic>,
              _currentUserId!,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[ChatProvider] Failed to load conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages for a specific conversation
  Future<void> loadMessages(int conversationId, {int page = 1}) async {
    if (page > 1 && (_isLoadingMoreByConversation[conversationId] ?? false)) return;
    if (page > 1 && !(_hasMoreByConversation[conversationId] ?? true)) return;

    if (page > 1) {
      _isLoadingMoreByConversation[conversationId] = true;
      notifyListeners();
    }

    try {
      final data = await ChatApiService.getMessages(conversationId, page: page);
      final messages = (data['messages'] as List<dynamic>? ?? [])
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
          
      final total = data['total'] as int? ?? 0;
      final limit = data['limit'] as int? ?? 15;

      if (page == 1) {
        _messagesByConversation[conversationId] = messages;
      } else {
        _messagesByConversation[conversationId] = [
          ...messages,
          ...(_messagesByConversation[conversationId] ?? []),
        ];
      }
      
      _currentPageByConversation[conversationId] = page;
      _hasMoreByConversation[conversationId] = (page * limit) < total;

      notifyListeners();
    } catch (e) {
      debugPrint('[ChatProvider] Failed to load messages: $e');
    } finally {
      if (page > 1) {
        _isLoadingMoreByConversation[conversationId] = false;
        notifyListeners();
      }
    }
  }

  /// Send a message: persist to backend (source of truth) + best-effort ZIM delivery
  Future<ChatMessage?> sendMessage({
    required int receiverId,
    required String content,
    int? conversationId,
    String messageType = 'TEXT',
  }) async {
    if (content.trim().isEmpty) return null;

    try {
      // 1. Persist to backend first — this is the source of truth
      final saved = await ChatApiService.sendMessage(
        receiverId: receiverId,
        content: content,
        messageType: messageType,
      );

      // 2. Add to local state
      ChatMessage? returnMessage;
      if (saved != null) {
        final message = ChatMessage.fromJson(saved);
        returnMessage = message;
        final convoId = message.conversationId;
        _messagesByConversation[convoId] ??= [];
        _messagesByConversation[convoId]!.add(message);
        notifyListeners();
        // Refresh conversations to pick up the new message silently in the listing
        loadConversations(showLoading: false);
      }

      // 3. Best-effort ZIM delivery (won't block if peer is offline/unregistered)
      ZegoService.instance
          .sendMessage(receiverId.toString(), content)
          .catchError((e) {
            debugPrint('[ChatProvider] ZIM delivery failed (non-fatal): $e');
            return null;
          });
      
      return returnMessage;
    } catch (e) {
      debugPrint('[ChatProvider] Failed to send message: $e');
      rethrow;
    }
  }

  /// Send a media message: ZIM upload -> ZIM delivery -> Backend Persist
  Future<ChatMessage?> sendMediaMessage({
    required int receiverId,
    required String filePath,
    required String messageType, // 'IMAGE', 'VIDEO', 'AUDIO'
    int? audioDuration,
  }) async {
    try {
      // 1. Create ZIM media message based on type
      ZIMMediaMessage? zimMediaMsg;
      if (messageType == 'IMAGE') {
        zimMediaMsg = ZIMImageMessage(filePath);
      } else if (messageType == 'VIDEO') {
        zimMediaMsg = ZIMVideoMessage(filePath);
      } else if (messageType == 'AUDIO') {
        final msg = ZIMAudioMessage(filePath);
        if (audioDuration != null) msg.audioDuration = audioDuration;
        zimMediaMsg = msg;
      } else {
        zimMediaMsg = ZIMFileMessage(filePath);
      }

      // 2. Upload and deliver via ZIM
      final result = await ZegoService.instance.sendMediaMessage(
        receiverId.toString(),
        zimMediaMsg,
      );

      if (result != null && result.message is ZIMMediaMessage) {
        final uploadedMsg = result.message as ZIMMediaMessage;
        final downloadUrl = uploadedMsg.fileDownloadUrl;

        // 3. Persist to backend
        final saved = await ChatApiService.sendMessage(
          receiverId: receiverId,
          content: downloadUrl.isNotEmpty ? downloadUrl : filePath,
          messageType: messageType,
          zegoMessageId: uploadedMsg.messageID.toString(),
        );

        // 4. Update local state
        ChatMessage? returnMessage;
        if (saved != null) {
          final message = ChatMessage.fromJson(saved);
          returnMessage = message;
          final convoId = message.conversationId;
          _messagesByConversation[convoId] ??= [];
          _messagesByConversation[convoId]!.add(message);
          notifyListeners();
          // Refresh conversations to pick up the new message silently in the listing
          loadConversations(showLoading: false);
        }
        return returnMessage;
      }
      return null;
    } catch (e) {
      debugPrint('[ChatProvider] Failed to send media message: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _zimSubscription?.cancel();
    super.dispose();
  }
}
