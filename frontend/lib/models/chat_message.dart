class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final String messageType;
  final String? zegoMessageId;
  final DateTime createdAt;
  final String? senderName;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.messageType = 'TEXT',
    this.zegoMessageId,
    required this.createdAt,
    this.senderName,
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
    this.lastMessageTime,
    required this.createdAt,
  });

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
      lastMessageTime: lastMsg?['createdAt'] != null
          ? DateTime.parse(lastMsg['createdAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
