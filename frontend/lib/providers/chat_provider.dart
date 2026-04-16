import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mylifepartner/models/chat_message.dart';
import 'package:mylifepartner/services/chat_service.dart';
import 'package:mylifepartner/services/zego_service.dart';

class ChatProvider extends ChangeNotifier {
  final Map<int, List<ChatMessage>> _messagesByConversation = {};
  List<ChatConversation> _conversations = [];
  bool _isLoading = false;
  int? _currentUserId;
  StreamSubscription? _zimSubscription;

  int? _activeUserId;
  final Set<int> _unreadUserIds = {};

  List<ChatConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;

  int? get activeUserId => _activeUserId;
  bool hasUnreadNudge(int userId) => _unreadUserIds.contains(userId);

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

    print("msg recieved is: $msg");
    // Do NOT persist to backend here, the sender is responsible for that.
    // Instead, we just show it up locally or show an unread nudge.
    final senderId = int.tryParse(msg.fromUserId);
    if (senderId == null || _currentUserId == null) return;

    // Vibrate the phone
    HapticFeedback.vibrate();

    final conversationIndex = _conversations.indexWhere((c) => c.otherUserId == senderId);
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
    try {
      final data = await ChatApiService.getMessages(conversationId, page: page);
      final messages = (data['messages'] as List<dynamic>? ?? [])
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
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

  /// Send a message: persist to backend (source of truth) + best-effort ZIM delivery
  Future<void> sendMessage({
    required int receiverId,
    required String content,
    int? conversationId,
    String messageType = 'TEXT',
  }) async {
    if (content.trim().isEmpty) return;

    try {
      // 1. Persist to backend first — this is the source of truth
      final saved = await ChatApiService.sendMessage(
        receiverId: receiverId,
        content: content,
        messageType: messageType,
      );

      // 2. Add to local state
      if (saved != null) {
        final message = ChatMessage.fromJson(saved);
        final convoId = message.conversationId;
        _messagesByConversation[convoId] ??= [];
        _messagesByConversation[convoId]!.add(message);
        notifyListeners();
      }

      // 3. Best-effort ZIM delivery (won't block if peer is offline/unregistered)
      ZegoService.instance
          .sendMessage(receiverId.toString(), content)
          .catchError((e) {
            debugPrint('[ChatProvider] ZIM delivery failed (non-fatal): $e');
            return null;
          });
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
