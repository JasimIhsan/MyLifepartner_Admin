import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mylifepartner/models/chat_message.dart';
import 'package:mylifepartner/services/chat_service.dart';
import 'package:mylifepartner/services/zego_service.dart';

class ChatProvider extends ChangeNotifier {
  final Map<int, List<ChatMessage>> _messagesByConversation = {};
  List<ChatConversation> _conversations = [];
  bool _isLoading = false;
  int? _currentUserId;
  StreamSubscription? _zimSubscription;

  List<ChatConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;

  List<ChatMessage> getMessages(int conversationId) {
    return _messagesByConversation[conversationId] ?? [];
  }

  void setCurrentUserId(int userId) {
    _currentUserId = userId;
  }

  /// Start listening for incoming ZIM messages
  void startListening() {
    _zimSubscription?.cancel();
    _zimSubscription = ZegoService.instance.onMessageReceived.listen((msg) {
      _handleIncomingMessage(msg);
    });
  }

  void _handleIncomingMessage(ZegoZIMMessage msg) {
    // We'll persist to backend and add to local state
    final senderId = int.tryParse(msg.fromUserId);
    if (senderId == null || _currentUserId == null) return;

    // Persist to backend in background
    ChatApiService.sendMessage(
      receiverId: _currentUserId!,
      content: msg.content,
      zegoMessageId: msg.messageID,
    ).catchError((e) {
      debugPrint('[ChatProvider] Failed to persist incoming message: $e');
      return null;
    });

    // Refresh conversations to pick up the new message
    loadConversations();
  }

  /// Load all conversations
  Future<void> loadConversations() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await ChatApiService.getConversations();
      _conversations = data
          .map((json) => ChatConversation.fromJson(
                json as Map<String, dynamic>,
                _currentUserId!,
              ))
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
    try {
      final data = await ChatApiService.getMessages(
        conversationId,
        page: page,
      );
      final messages = (data['messages'] as List<dynamic>? ?? [])
          .map((json) =>
              ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      if (page == 1) {
        _messagesByConversation[conversationId] = messages;
      } else {
        _messagesByConversation[conversationId] = [
          ...messages,
          ...(_messagesByConversation[conversationId] ?? []),
        ];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatProvider] Failed to load messages: $e');
    }
  }

  /// Send a message: persist to backend + send via ZIM
  Future<void> sendMessage({
    required int receiverId,
    required String content,
    int? conversationId,
  }) async {
    if (content.trim().isEmpty) return;

    try {
      // 1. Send via ZIM for real-time delivery
      await ZegoService.instance
          .sendMessage(receiverId.toString(), content);

      // 2. Persist to backend
      final saved = await ChatApiService.sendMessage(
        receiverId: receiverId,
        content: content,
      );

      // 3. Add to local state
      if (saved != null) {
        final message = ChatMessage.fromJson(saved);
        final convoId = message.conversationId;
        _messagesByConversation[convoId] ??= [];
        _messagesByConversation[convoId]!.add(message);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatProvider] Failed to send message: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _zimSubscription?.cancel();
    super.dispose();
  }
}
