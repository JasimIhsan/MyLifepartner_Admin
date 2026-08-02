class MatchImage {
  final String imageUrl;
  final bool isPrimary;
  final bool isBlurred;

  MatchImage({
    required this.imageUrl,
    required this.isPrimary,
    this.isBlurred = false,
  });

  factory MatchImage.fromJson(Map<String, dynamic> json) {
    return MatchImage(
      imageUrl: json['imageUrl'] as String,
      isPrimary: json['isPrimary'] as bool,
      isBlurred: json['isBlurred'] as bool? ?? false,
    );
  }
}

enum InteractionState {
  none('NONE'),
  interestSent('INTEREST_SENT'),
  interestReceived('INTEREST_RECEIVED'),
  matched('MATCHED');

  final String value;
  const InteractionState(this.value);

  factory InteractionState.fromString(String status) {
    return InteractionState.values.firstWhere(
      (e) => e.value == status,
      orElse: () => InteractionState.none,
    );
  }
}

class MatchRecommendation {
  final int id;
  final int userId;
  final String name;
  final int age;
  final bool isVerified;
  final int? heightCm;
  final String? city;
  final String? state;
  final String? country;
  final String? occupation;
  final String? maritalStatus;
  final int matchPercentage;
  final List<String> compatibilityHighlights;
  final List<MatchImage> images;
  final InteractionState interactionState;
  final String createdAt;
  final String lastLoginAt;
  final bool viewerPrivacyEnabled;
  final bool targetPrivacyEnabled;
  final String? imageAccessRequestStatus;

  MatchRecommendation({
    required this.id,
    required this.userId,
    required this.name,
    required this.age,
    required this.isVerified,
    this.heightCm,
    this.city,
    this.state,
    this.country,
    this.occupation,
    this.maritalStatus,
    required this.matchPercentage,
    required this.compatibilityHighlights,
    required this.images,
    required this.interactionState,
    required this.createdAt,
    required this.lastLoginAt,
    this.viewerPrivacyEnabled = false,
    this.targetPrivacyEnabled = false,
    this.imageAccessRequestStatus,
  });

  factory MatchRecommendation.fromJson(Map<String, dynamic> json) {
    return MatchRecommendation(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      name: json['name'] as String? ?? 'User',
      isVerified: json['isVerified'] as bool? ?? false,
      age: json['age'] as int? ?? 0,
      heightCm: json['heightCm'] as int?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      occupation: json['occupation'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      matchPercentage: (json['matchPercentage'] as num?)?.toInt() ?? 0,
      compatibilityHighlights:
          (json['compatibilityHighlights'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => MatchImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      interactionState: InteractionState.fromString(
        json['interactionState'] as String? ?? 'NONE',
      ),
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      lastLoginAt:
          json['lastLoginAt'] as String? ?? DateTime.now().toIso8601String(),
      viewerPrivacyEnabled: json['viewerPrivacyEnabled'] as bool? ?? false,
      targetPrivacyEnabled: json['targetPrivacyEnabled'] as bool? ?? false,
      imageAccessRequestStatus: json['imageAccessRequestStatus'] as String?,
    );
  }
}
