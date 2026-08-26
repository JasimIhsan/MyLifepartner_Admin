class MatchImage {
  final int imageId;
  final String imageUrl;
  final String presignedImageUrl;
  final bool isPrimary;
  final bool isBlurred;

  MatchImage({
    required this.imageId,
    required this.imageUrl,
    required this.presignedImageUrl,
    required this.isPrimary,
    this.isBlurred = false,
  });

  factory MatchImage.fromJson(Map<String, dynamic> json) {
    final parsedImageUrl =
        json['presignedImageUrl'] as String? ??
        json['imageUrl'] as String? ??
        '';

    return MatchImage(
      imageId: json['imageId'] as int? ?? json['id'] as int? ?? 0,
      imageUrl: parsedImageUrl,
      presignedImageUrl: parsedImageUrl,
      isPrimary: json['isPrimary'] as bool? ?? false,
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
  final bool isFoundingMember;
  final bool isPremium;
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
  // Extended profile-detail fields
  final String? gender;
  final String? motherTongue;
  final String? highestEducation;
  final String? bio;
  final String? childrenStatus;
  final String? drinkingHabit;
  final String? emotionalReadiness;
  final List<String> languages;
  final String? lookingFor;
  final String? relationshipTimeline;
  final String? smokingHabit;

  MatchRecommendation({
    required this.id,
    required this.userId,
    required this.name,
    required this.age,
    required this.isVerified,
    required this.isFoundingMember,
    this.isPremium = false,
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
    this.gender,
    this.motherTongue,
    this.highestEducation,
    this.bio,
    this.childrenStatus,
    this.drinkingHabit,
    this.emotionalReadiness,
    this.languages = const [],
    this.lookingFor,
    this.relationshipTimeline,
    this.smokingHabit,
  });

  factory MatchRecommendation.fromJson(Map<String, dynamic> json) {
    return MatchRecommendation(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      name: json['name'] as String? ?? 'User',
      isVerified: json['isVerified'] as bool? ?? false,
      isFoundingMember: json['isFoundingMember'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
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
      // Extended profile-detail fields
      gender: json['gender'] as String?,
      motherTongue: json['motherTongue'] as String?,
      highestEducation: json['highestEducation'] as String?,
      bio: json['bio'] as String?,
      childrenStatus: json['childrenStatus'] as String?,
      drinkingHabit: json['drinkingHabit'] as String?,
      emotionalReadiness: json['emotionalReadiness'] as String?,
      languages: (json['languages'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      lookingFor: json['lookingFor'] as String?,
      relationshipTimeline: json['relationshipTimeline'] as String?,
      smokingHabit: json['smokingHabit'] as String?,
    );
  }

  MatchImage? get primaryOrFirstImage {
    final primaryImages = images.where((image) => image.isPrimary);
    if (primaryImages.isNotEmpty) return primaryImages.first;
    if (images.isNotEmpty) return images.first;
    return null;
  }

  /// Converts this recommendation to a [Map] compatible with
  /// the profile detail UI widgets (which consume a raw map from the API).
  Map<String, dynamic> toDetailMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'age': age,
      'isVerified': isVerified,
      'isFoundingMember': isFoundingMember,
      'isPremium': isPremium,
      'heightCm': heightCm,
      'city': city,
      'state': state,
      'country': country,
      'occupation': occupation,
      'maritalStatus': maritalStatus,
      'matchPercentage': matchPercentage,
      'compatibilityHighlights': compatibilityHighlights,
      'images': images
          .map((img) => {
                'id': img.imageId,
                'imageId': img.imageId,
                'imageUrl': img.presignedImageUrl,
                'presignedImageUrl': img.presignedImageUrl,
                'isPrimary': img.isPrimary,
                'isBlurred': img.isBlurred,
              })
          .toList(),
      'interactionState': interactionState.value,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'viewerPrivacyEnabled': viewerPrivacyEnabled,
      'targetPrivacyEnabled': targetPrivacyEnabled,
      'imageAccessRequestStatus': imageAccessRequestStatus,
      'gender': gender,
      'motherTongue': motherTongue,
      'highestEducation': highestEducation,
      'bio': bio,
      'childrenStatus': childrenStatus,
      'drinkingHabit': drinkingHabit,
      'emotionalReadiness': emotionalReadiness,
      'languages': languages,
      'lookingFor': lookingFor,
      'relationshipTimeline': relationshipTimeline,
      'smokingHabit': smokingHabit,
    };
  }
}
