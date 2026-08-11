class NotificationTypes {
  static const String newMessage = 'NEW_MESSAGE';
  static const String newLike = 'NEW_LIKE';
  static const String newMatch = 'NEW_MATCH';
  static const String interestAccepted = 'INTEREST_ACCEPTED';
  static const String missedCall = 'MISSED_CALL';
  static const String imageAccessRequested = 'IMAGE_ACCESS_REQUESTED';
  static const String imageAccessGranted = 'IMAGE_ACCESS_GRANTED';
  static const String profileApproved = 'PROFILE_APPROVED';
  static const String profileRejected = 'PROFILE_REJECTED';
  static const String subscriptionSuccess = 'SUBSCRIPTION_SUCCESS';
  static const String subscriptionExpiring = 'SUBSCRIPTION_EXPIRING';
  static const String paymentFailed = 'PAYMENT_FAILED';
}

/// Represents the data payload of a push notification.
class NotificationData {
  final String type;
  final String? entityId;
  final String? conversationId;
  final String? profileId;

  NotificationData({
    required this.type,
    this.entityId,
    this.conversationId,
    this.profileId,
  });

  factory NotificationData.fromMap(Map<String, dynamic> map) {
    return NotificationData(
      type: map['type']?.toString() ?? '',
      entityId: map['entityId']?.toString(),
      conversationId: map['conversationId']?.toString(),
      profileId: map['profileId']?.toString(),
    );
  }
}
