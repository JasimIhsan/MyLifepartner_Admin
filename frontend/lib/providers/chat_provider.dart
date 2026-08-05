import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/models/chat_message.dart';
import 'package:life_partner_again/services/chat_service.dart';
import 'package:life_partner_again/services/zego_service.dart';
import 'package:path_provider/path_provider.dart';
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
  StreamSubscription? _userStatusSubscription;
  StreamSubscription? _tokenSubscription;

  int? _activeUserId;
  final Set<int> _unreadUserIds = {};
  final Set<int> _downloadedMedia = {};

  final Map<int, ZIMUserOnlineStatus> _onlineStatusByUser = {};
  final Map<int, bool> _typingUsers = {};
  final Map<int, Timer> _typingTimers = {};
  Timer? _statusTimer;
  final Set<int> _subscribedUserIds = {};
  final Map<int, DateTime> _lastSeenByUser = {};
  Timer? _presenceHeartbeatTimer;
  Timer? _presenceCleanupTimer;

  bool isUserOnline(int userId) =>
      _onlineStatusByUser[userId] == ZIMUserOnlineStatus.online;
  ZIMUserOnlineStatus getUserStatus(int userId) =>
      _onlineStatusByUser[userId] ?? ZIMUserOnlineStatus.offline;
  bool isUserTyping(int userId) => _typingUsers[userId] ?? false;

  List<ChatConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;

  bool hasMoreMessages(int conversationId) =>
      _hasMoreByConversation[conversationId] ?? true;
  bool isLoadingMore(int conversationId) =>
      _isLoadingMoreByConversation[conversationId] ?? false;
  int currentPage(int conversationId) =>
      _currentPageByConversation[conversationId] ?? 1;

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

  /// Initialize global ZIM listeners on app start
  void initListeners() {
    _zimSubscription?.cancel();
    _zimSubscription = ZegoService.instance.onMessageReceived.listen((msg) {
      _handleIncomingMessage(msg);
    });

    _userStatusSubscription?.cancel();
    _userStatusSubscription = ZegoService.instance.onUserStatusUpdated.listen((
      statusList,
    ) {
      for (final status in statusList) {
        final uId = int.tryParse(status.userID);
        if (uId != null) {
          _onlineStatusByUser[uId] = status.onlineStatus;
        }
      }
      notifyListeners();
    });

    _tokenSubscription?.cancel();
    _tokenSubscription = ZegoService.instance.onTokenWillExpire.listen((
      _,
    ) async {
      try {
        final tokenData = await ChatApiService.getZegoToken();
        if (tokenData != null && tokenData['token'] != null) {
          await ZegoService.instance.renewToken(tokenData['token']);
        }
      } catch (e) {
        debugPrint('[ChatProvider] Token auto-renew failed: $e');
      }
    });

    _startPresenceSystem();
  }

  /// Kept for backward compatibility, but listeners are active by default now.
  void startListening() {
    // Automatically trigger subscriptions for any queued IDs now that login is ready
    if (_subscribedUserIds.isNotEmpty && ZegoService.instance.isLoggedIn) {
      subscribeToUsersStatus(_subscribedUserIds.toList());
    }
  }

  void _setTypingState(int userId, bool isTyping) {
    _typingTimers[userId]?.cancel();
    _typingTimers.remove(userId);

    if (isTyping) {
      _typingUsers[userId] = true;
      // Timeout after 8 seconds of inactivity
      _typingTimers[userId] = Timer(const Duration(seconds: 8), () {
        _typingUsers[userId] = false;
        notifyListeners();
      });
    } else {
      _typingUsers[userId] = false;
    }
    notifyListeners();
  }

  Future<void> sendTypingStatus(int receiverId, bool isTyping) async {
    if (_currentUserId == null) {
      debugPrint(
        '[ChatProvider] Cannot send typing status: _currentUserId is null',
      );
      return;
    }
    final payload = jsonEncode({
      'type': 'typing',
      'senderId': _currentUserId.toString(),
      'receiverId': receiverId.toString(),
      'isTyping': isTyping,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint(
      '[ChatProvider] Sending typing status to $receiverId: isTyping=$isTyping',
    );
    ZegoService.instance
        .sendMessage(receiverId.toString(), payload)
        .then((result) {
          debugPrint(
            '[ChatProvider] Sent typing status successfully to $receiverId',
          );
        })
        .catchError((e) {
          debugPrint('[ChatProvider] sendTypingStatus failed: $e');
          return null;
        });
  }

  void _startStatusTimer() {
    _startPresenceSystem();
  }

  void _stopStatusTimer() {
    _stopPresenceSystem();
  }

  void _startPresenceSystem() {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) {
      _sendPresenceHeartbeat();
    });

    _presenceCleanupTimer?.cancel();
    _presenceCleanupTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _cleanupOfflineUsers();
    });

    _sendPresenceHeartbeat();
  }

  void _stopPresenceSystem() {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    _presenceCleanupTimer?.cancel();
    _presenceCleanupTimer = null;
  }

  void _sendPresenceHeartbeat() {
    if (!ZegoService.instance.isLoggedIn || _currentUserId == null) return;

    final Set<int> targetUserIds = {};
    for (final convo in _conversations) {
      targetUserIds.add(convo.otherUserId);
    }
    targetUserIds.addAll(_subscribedUserIds);

    if (targetUserIds.isEmpty) return;

    final payload = jsonEncode({
      'type': 'presence',
      'senderId': _currentUserId.toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    for (final uId in targetUserIds) {
      ZegoService.instance
          .sendMessage(uId.toString(), payload)
          .catchError((e) => null);
    }
  }

  void _cleanupOfflineUsers() {
    final now = DateTime.now();
    bool changed = false;
    _lastSeenByUser.forEach((uId, lastSeen) {
      if (_onlineStatusByUser[uId] == ZIMUserOnlineStatus.online) {
        if (now.difference(lastSeen).inSeconds > 40) {
          _onlineStatusByUser[uId] = ZIMUserOnlineStatus.offline;
          changed = true;
          debugPrint(
            '[ChatProvider] User $uId marked offline due to heartbeat timeout',
          );
        }
      }
    });
    if (changed) {
      notifyListeners();
    }
  }

  Future<void> subscribeToUserStatus(int userId) async {
    _subscribedUserIds.add(userId);
    _startStatusTimer();
    if (!ZegoService.instance.isLoggedIn) {
      debugPrint(
        '[ChatProvider] subscribeToUserStatus: ZIM not logged in yet. Queued status subscription for $userId.',
      );
      return;
    }
    try {
      final config = ZIMUserStatusSubscribeConfig();
      debugPrint('[ChatProvider] Subscribing to user status: $userId');
      final result = await ZIM.getInstance()?.subscribeUsersStatus([
        userId.toString(),
      ], config);
      debugPrint(
        '[ChatProvider] Subscribed successfully to $userId, result: $result',
      );
    } catch (e) {
      debugPrint('[ChatProvider] subscribeToUserStatus error: $e');
    }
    await _queryUserStatus(userId);
  }

  Future<void> subscribeToUsersStatus(List<int> userIds) async {
    if (userIds.isEmpty) return;
    _subscribedUserIds.addAll(userIds);
    _startStatusTimer();
    if (!ZegoService.instance.isLoggedIn) {
      debugPrint(
        '[ChatProvider] subscribeToUsersStatus: ZIM not logged in yet. Queued status subscriptions.',
      );
      return;
    }
    try {
      final config = ZIMUserStatusSubscribeConfig();
      final idsStr = userIds.map((id) => id.toString()).toList();
      debugPrint('[ChatProvider] Subscribing to user statuses: $idsStr');
      final result = await ZIM.getInstance()?.subscribeUsersStatus(
        idsStr,
        config,
      );
      debugPrint(
        '[ChatProvider] Subscribed successfully to $idsStr, result: $result',
      );
    } catch (e) {
      debugPrint('[ChatProvider] subscribeToUsersStatus error: $e');
    }

    try {
      final idsStr = userIds.map((id) => id.toString()).toList();
      debugPrint('[ChatProvider] Batch querying user statuses: $idsStr');
      final result = await ZIM.getInstance()?.queryUsersStatus(idsStr);
      if (result != null) {
        debugPrint(
          '[ChatProvider] Batch query result count: ${result.userStatusList.length}',
        );
        for (final status in result.userStatusList) {
          final uId = int.tryParse(status.userID);
          if (uId != null) {
            debugPrint(
              '[ChatProvider] User $uId status is ${status.onlineStatus}',
            );
            _onlineStatusByUser[uId] = status.onlineStatus;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatProvider] queryUsersStatus batch error: $e');
    }
  }

  Future<bool> queryUserStatusNow(int userId) async {
    try {
      final result = await ZIM.getInstance()?.queryUsersStatus([
        userId.toString(),
      ]);
      if (result != null && result.userStatusList.isNotEmpty) {
        final status = result.userStatusList.first;
        _onlineStatusByUser[userId] = status.onlineStatus;
        notifyListeners();
        return status.onlineStatus == ZIMUserOnlineStatus.online;
      }
    } catch (e) {
      debugPrint('[ChatProvider] queryUserStatusNow error: $e');
      // If "User Presence" is not enabled in the ZEGOCLOUD console, this throws an error.
      // We return true to fail open, otherwise users can never call each other.
      return true;
    }
    return true; // Fail open if unknown
  }

  Future<void> _queryUserStatus(int userId) async {
    try {
      debugPrint('[ChatProvider] Querying user status: $userId');
      final result = await ZIM.getInstance()?.queryUsersStatus([
        userId.toString(),
      ]);
      if (result != null) {
        debugPrint(
          '[ChatProvider] Query result count for $userId: ${result.userStatusList.length}',
        );
        for (final status in result.userStatusList) {
          final uId = int.tryParse(status.userID);
          if (uId != null) {
            debugPrint(
              '[ChatProvider] User $uId status is ${status.onlineStatus}',
            );
            _onlineStatusByUser[uId] = status.onlineStatus;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatProvider] queryUsersStatus error: $e');
    }
  }

  Future<void> unsubscribeFromUserStatus(int userId) async {
    _subscribedUserIds.remove(userId);
    if (_subscribedUserIds.isEmpty) {
      _stopStatusTimer();
    }
    try {
      await ZIM.getInstance()?.unsubscribeUsersStatus([userId.toString()]);
    } catch (e) {
      debugPrint('[ChatProvider] unsubscribeFromUserStatus error: $e');
    }
  }

  Future<void> subscribeToAllConversationsStatus() async {
    if (_conversations.isEmpty) return;
    final userIds = _conversations
        .map((c) => c.otherUserId.toString())
        .toList();
    try {
      final config = ZIMUserStatusSubscribeConfig();
      await ZIM.getInstance()?.subscribeUsersStatus(userIds, config);
    } catch (e) {
      debugPrint('[ChatProvider] subscribeToAllConversationsStatus error: $e');
    }
    await _queryAllConversationsStatus();
  }

  Future<void> _queryAllConversationsStatus() async {
    if (_conversations.isEmpty) return;
    final userIds = _conversations
        .map((c) => c.otherUserId.toString())
        .toList();
    try {
      final result = await ZIM.getInstance()?.queryUsersStatus(userIds);
      if (result != null) {
        for (final status in result.userStatusList) {
          final uId = int.tryParse(status.userID);
          if (uId != null) {
            _onlineStatusByUser[uId] = status.onlineStatus;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatProvider] _queryAllConversationsStatus error: $e');
    }
  }

  void _handleIncomingMessage(ZegoZIMMessage msg) {
    debugPrint(
      '[ChatProvider] Received ZIM message from ${msg.fromUserId}, content: ${msg.content}',
    );
    final senderId = int.tryParse(msg.fromUserId);
    if (senderId == null || _currentUserId == null) {
      debugPrint(
        '[ChatProvider] early return parsing msg: senderId=$senderId, _currentUserId=$_currentUserId',
      );
      return;
    }

    // Since they sent us a message, they must be online
    _onlineStatusByUser[senderId] = ZIMUserOnlineStatus.online;
    _lastSeenByUser[senderId] = DateTime.now();

    if (msg.content.startsWith('{')) {
      try {
        final data = jsonDecode(msg.content) as Map<String, dynamic>;
        debugPrint(
          '[ChatProvider] Parsed incoming ZIM JSON type: ${data['type']}',
        );
        if (data['type'] == 'presence') {
          debugPrint(
            '[ChatProvider] Received presence heartbeat from $senderId',
          );
          _onlineStatusByUser[senderId] = ZIMUserOnlineStatus.online;
          _lastSeenByUser[senderId] = DateTime.now();
          notifyListeners();
        } else if (data['type'] == 'typing' ||
            data['type'] == 'typing_status') {
          final isTyping = data['isTyping'] as bool? ?? false;
          debugPrint(
            '[ChatProvider] Setting typing status for $senderId to $isTyping',
          );
          _setTypingState(senderId, isTyping);
          if (isTyping) {
            _onlineStatusByUser[senderId] = ZIMUserOnlineStatus.online;
            _lastSeenByUser[senderId] = DateTime.now();
          }
        }
      } catch (e) {
        debugPrint('[ChatProvider] failed to parse ZIM JSON msg: $e');
      }
      return;
    }

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
      // Dedup by messageID
      if (conversation != null) {
        final existingMessages = _messagesByConversation[conversation.id] ?? [];
        if (existingMessages.any((m) => m.zegoMessageId == msg.messageID)) {
          debugPrint(
            '[ChatProvider] Dedup: ignored duplicate message ${msg.messageID}',
          );
          return;
        }

        final message = ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch,
          conversationId: conversation.id,
          senderId: senderId,
          content: msg.content,
          messageType: msg.messageType,
          zegoMessageId: msg.messageID,
          createdAt: DateTime.now(),
        );

        _messagesByConversation[conversation.id] ??= [];
        _messagesByConversation[conversation.id]!.add(message);

        if (message.messageType == 'AUDIO' &&
            message.content.startsWith('http')) {
          _preloadAudio(message.content);
        }
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
      subscribeToAllConversationsStatus();
    } catch (e) {
      debugPrint('[ChatProvider] Failed to load conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages for a specific conversation
  Future<void> loadMessages(int conversationId, {int page = 1}) async {
    if (page > 1 && (_isLoadingMoreByConversation[conversationId] ?? false)) {
      return;
    }
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

      for (final m in messages) {
        if (m.messageType == 'AUDIO' && m.content.startsWith('http')) {
          _preloadAudio(m.content);
        }
      }

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

  Future<void> _preloadAudio(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final safeHash = url.hashCode.abs().toString();
      final file = File('${dir.path}/audio_cache_$safeHash.m4a');
      if (!await file.exists() || (await file.length()) == 0) {
        await Dio().download(url, file.path);
        debugPrint(
          '[ChatProvider] Successfully pre-downloaded audio to ${file.path}',
        );
      }
    } catch (e) {
      debugPrint('[ChatProvider] _preloadAudio failed for $url: $e');
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
    int? convoId = _conversations
        .where((c) => c.otherUserId == receiverId)
        .firstOrNull
        ?.id;
    int tempId = DateTime.now().microsecondsSinceEpoch;

    // 1. Optimistic insert
    if (convoId != null && _currentUserId != null) {
      final optimisticMessage = ChatMessage(
        id: tempId,
        conversationId: convoId,
        senderId: _currentUserId!,
        content: filePath,
        messageType: messageType,
        createdAt: DateTime.now(),
        status: 'uploading',
        uploadProgress: 0.0,
      );
      _messagesByConversation[convoId] ??= [];
      _messagesByConversation[convoId]!.add(optimisticMessage);
      notifyListeners();
    }

    try {
      // 2. Create ZIM media message based on type
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

      // 3. Upload and deliver via ZIM
      final result = await ZegoService.instance.sendMediaMessage(
        receiverId.toString(),
        zimMediaMsg,
        onMediaUploadingProgress: (message, currentFileSize, totalFileSize) {
          if (convoId != null && totalFileSize > 0) {
            final progress = currentFileSize / totalFileSize;
            final msgs = _messagesByConversation[convoId];
            if (msgs != null) {
              final index = msgs.indexWhere((m) => m.id == tempId);
              if (index != -1) {
                final old = msgs[index];
                msgs[index] = ChatMessage(
                  id: old.id,
                  conversationId: old.conversationId,
                  senderId: old.senderId,
                  content: old.content,
                  messageType: old.messageType,
                  createdAt: old.createdAt,
                  status: 'uploading',
                  uploadProgress: progress,
                );
                notifyListeners();
              }
            }
          }
        },
      );

      if (result != null && result.message is ZIMMediaMessage) {
        final uploadedMsg = result.message as ZIMMediaMessage;
        final downloadUrl = uploadedMsg.fileDownloadUrl;

        // 4. Persist to backend
        final saved = await ChatApiService.sendMessage(
          receiverId: receiverId,
          content: downloadUrl.isNotEmpty ? downloadUrl : filePath,
          messageType: messageType,
          zegoMessageId: uploadedMsg.messageID.toString(),
        );

        // 5. Update local state with final message
        ChatMessage? returnMessage;
        if (saved != null) {
          final message = ChatMessage.fromJson(saved);
          returnMessage = message;
          final finalConvoId = message.conversationId;

          _messagesByConversation[finalConvoId] ??= [];
          // Replace optimistic message
          final msgs = _messagesByConversation[finalConvoId]!;
          final index = msgs.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            msgs[index] = message;
          } else {
            msgs.add(message);
          }
          notifyListeners();
          loadConversations(showLoading: false);
        }
        return returnMessage;
      } else {
        // Failed ZIM send
        _markMessageFailed(convoId, tempId);
      }
      return null;
    } catch (e) {
      debugPrint('[ChatProvider] Failed to send media message: $e');
      _markMessageFailed(convoId, tempId);
      rethrow;
    }
  }

  void _markMessageFailed(int? convoId, int tempId) {
    if (convoId != null) {
      final msgs = _messagesByConversation[convoId];
      if (msgs != null) {
        final index = msgs.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          final old = msgs[index];
          msgs[index] = ChatMessage(
            id: old.id,
            conversationId: old.conversationId,
            senderId: old.senderId,
            content: old.content,
            messageType: old.messageType,
            createdAt: old.createdAt,
            status: 'failed',
          );
          notifyListeners();
        }
      }
    }
  }

  @override
  void dispose() {
    _zimSubscription?.cancel();
    _userStatusSubscription?.cancel();
    _tokenSubscription?.cancel();
    _statusTimer?.cancel();
    _stopPresenceSystem();
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
