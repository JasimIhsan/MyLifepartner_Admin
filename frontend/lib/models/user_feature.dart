class UserFeature {
  final int id;
  final int userId;

  bool get canAudioCall => maxAudioCallMinutes > 0;
  bool get canVideoCall => maxVideoCallMinutes > 0;
  bool get canSendMessage => maxMessages > 0;
  final bool isProfileBlurEnabled;

  final int maxInterests;
  final int remainingInterests;

  final int maxVideoCallMinutes;
  final int remainingVideoCallMinutes;

  final int maxAudioCallMinutes;
  final int remainingAudioCallMinutes;

  final int maxMessages;
  final int remainingMessages;

  UserFeature({
    required this.id,
    required this.userId,

    required this.isProfileBlurEnabled,
    required this.maxInterests,
    required this.remainingInterests,
    required this.maxVideoCallMinutes,
    required this.remainingVideoCallMinutes,
    required this.maxAudioCallMinutes,
    required this.remainingAudioCallMinutes,
    required this.maxMessages,
    required this.remainingMessages,
  });

  factory UserFeature.fromJson(Map<String, dynamic> json) {
    return UserFeature(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,

      isProfileBlurEnabled: json['isProfileBlurEnabled'] ?? false,
      maxInterests: json['maxInterests'] ?? 0,
      remainingInterests:
          (json['maxInterests'] ?? 0) - (json['interests'] ?? 0),
      maxVideoCallMinutes: json['maxVideoCallMinutes'] ?? 0,
      remainingVideoCallMinutes:
          (json['maxVideoCallMinutes'] ?? 0) - (json['videoCallMinutes'] ?? 0),
      maxAudioCallMinutes: json['maxAudioCallMinutes'] ?? 0,
      remainingAudioCallMinutes:
          (json['maxAudioCallMinutes'] ?? 0) - (json['audioCallMinutes'] ?? 0),
      maxMessages: json['maxMessages'] ?? 0,
      remainingMessages: (json['maxMessages'] ?? 0) - (json['messages'] ?? 0),
    );
  }
}
