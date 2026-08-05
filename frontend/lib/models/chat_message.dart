import 'dart:convert' as dart_convert;

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final String messageType;
  final String? zegoMessageId;
  final DateTime createdAt;
  final String? senderName;
  final String status; // 'sent', 'processing', 'uploading', 'failed'
  final double uploadProgress; 

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.messageType = 'TEXT',
    this.zegoMessageId,
    required this.createdAt,
    this.senderName,
    this.status = 'sent',
    this.uploadProgress = 0.0,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversationId'] as int,
      senderId: json['senderId'] as int,
      content: json['content'] as String,
      messageType: json['messageType'] as String? ?? 'TEXT',
      zegoMessageId: json['zegoMessageId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      senderName: json['sender']?['profile']?['name'] as String?,
    );
  }
}

class ChatConversation {
  final int id;
  final int userOneId;
  final int userTwoId;
  final String? otherUserName;
  final String? otherUserImage;
  final int otherUserId;
  final String? lastMessage;
  final String lastMessageType;
  final DateTime? lastMessageTime;
  final DateTime createdAt;

  ChatConversation({
    required this.id,
    required this.userOneId,
    required this.userTwoId,
    this.otherUserName,
    this.otherUserImage,
    required this.otherUserId,
    this.lastMessage,
    this.lastMessageType = 'TEXT',
    this.lastMessageTime,
    required this.createdAt,
  });

  /// Returns a clean UI string avoiding raw JSON for CALL_LOG types
  String get displayLastMessage {
    if (lastMessage == null) return 'Tap to start chatting';

    // Check if messageType is explicitly CALL_LOG or if the content is a JSON call log
    if (lastMessageType == 'CALL_LOG' ||
        (lastMessage!.startsWith('{') && lastMessage!.contains('"CALL_LOG"'))) {
      try {
        final Map<String, dynamic> data = dart_convert.jsonDecode(lastMessage!);
        final isVideo = data['callType'] == 'video';
        final status = data['status'] as String?;
        final isMissed =
            status == 'canceled' ||
            status == 'missed' ||
            status == 'declined' ||
            status == 'timeout';
        final callTypeName = isVideo ? 'Video call' : 'Audio call';
        return isMissed ? 'Missed $callTypeName' : callTypeName;
      } catch (_) {
        // Fallback in case it's not valid JSON
      }
    }

    // Check if it's a ZegoCloud media URL
    if (lastMessage!.contains('zim/file_access')) {
      return 'Attachment';
    }

    return lastMessage!;
  }

  factory ChatConversation.fromJson(
    Map<String, dynamic> json,
    int currentUserId,
  ) {
    final userOneId = json['userOneId'] as int;
    final userTwoId = json['userTwoId'] as int;
    final isUserOne = currentUserId == userOneId;

    final otherUser = isUserOne ? json['userTwo'] : json['userOne'];
    final otherProfile = otherUser?['profile'];

    final messages = json['messages'] as List<dynamic>? ?? [];
    final lastMsg = messages.isNotEmpty ? messages.first : null;

    final images = otherProfile?['images'] as List<dynamic>? ?? [];
    final primaryImage = images.isNotEmpty ? images.first['imageUrl'] : null;

    return ChatConversation(
      id: json['id'] as int,
      userOneId: userOneId,
      userTwoId: userTwoId,
      otherUserId: isUserOne ? userTwoId : userOneId,
      otherUserName: otherProfile?['name'] as String?,
      otherUserImage: primaryImage as String?,
      lastMessage: lastMsg?['content'] as String?,
      lastMessageType: lastMsg?['messageType'] as String? ?? 'TEXT',
      lastMessageTime: lastMsg?['createdAt'] != null
          ? DateTime.parse(lastMsg['createdAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
