class MatchImage {
  final String imageUrl;
  final bool isPrimary;

  MatchImage({required this.imageUrl, required this.isPrimary});

  factory MatchImage.fromJson(Map<String, dynamic> json) {
    return MatchImage(
      imageUrl: json['imageUrl'] as String,
      isPrimary: json['isPrimary'] as bool,
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
  final String name;
  final int age;
  final int? heightCm;
  final String? city;
  final String? religion;
  final String? occupation;
  final int matchPercentage;
  final List<String> compatibilityHighlights;
  final List<MatchImage> images;
  final InteractionState interactionState;

  MatchRecommendation({
    required this.id,
    required this.name,
    required this.age,
    this.heightCm,
    this.city,
    this.religion,
    this.occupation,
    required this.matchPercentage,
    required this.compatibilityHighlights,
    required this.images,
    required this.interactionState,
  });

  factory MatchRecommendation.fromJson(Map<String, dynamic> json) {
    return MatchRecommendation(
      id: json['id'] as int,
      name: json['name'] as String,
      age: json['age'] as int,
      heightCm: json['heightCm'] as int?,
      city: json['city'] as String?,
      religion: json['religion'] as String?,
      occupation: json['occupation'] as String?,
      matchPercentage: json['matchPercentage'] as int,
      compatibilityHighlights:
          (json['compatibilityHighlights'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toList(),
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => MatchImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      interactionState: InteractionState.fromString(
        json['interactionState'] as String? ?? 'NONE',
      ),
    );
  }
}
