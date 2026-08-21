class SendOtpResponse {
  final bool success;
  final String message;
  final dynamic data;

  SendOtpResponse({required this.success, required this.message, this.data});

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class InitiateAuthResponse {
  final bool success;
  final String message;
  final bool exists;

  InitiateAuthResponse({
    required this.success,
    required this.message,
    required this.exists,
  });

  factory InitiateAuthResponse.fromJson(Map<String, dynamic> json) {
    return InitiateAuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      exists: json['data']?['exists'] ?? false,
    );
  }
}

class SimpleMessageResponse {
  final bool success;
  final String message;

  SimpleMessageResponse({required this.success, required this.message});

  factory SimpleMessageResponse.fromJson(Map<String, dynamic> json) {
    return SimpleMessageResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class AuthResultResponse {
  final bool success;
  final String message;
  final String accessToken;
  final String refreshToken;
  final User? user;

  AuthResultResponse({
    required this.success,
    required this.message,
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory AuthResultResponse.fromJson(Map<String, dynamic> json) {
    return AuthResultResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      accessToken: json['data']?['accessToken'] ?? '',
      refreshToken: json['data']?['refreshToken'] ?? '',
      user: json['data'] != null && json['data']['user'] != null
          ? User.fromJson(json['data']['user'])
          : null,
    );
  }
}

class User {
  final int id;

  final String profileStatus;
  final bool hasCompletedBasicDetails;
  final bool hasCompletedImageUpload;
  final bool hasCompletedPartnerPreference;
  final String? selfieStatus;
  final bool isVerified;
  final bool isFoundingMember;
  final bool isPremium;
  final DateTime? foundingMemberSince;
  final String? name;
  final String? email;

  // Profile demographics
  final String? gender;
  final DateTime? dateOfBirth;
  final String? maritalStatus;
  final int? heightCm;
  final String? caste;
  final String? motherTongue;
  final String? city;
  final String? state;
  final String? country;
  final String? highestEducation;
  final String? occupation;
  final String? bio;
  final int? profileCompletion;
  final String? childrenStatus;
  final String? emotionalReadiness;
  final String? lookingFor;
  final String? relationshipTimeline;
  final List<String> languages;
  final String? smokingHabit;
  final String? drinkingHabit;
  final bool privacyEnabled;

  User({
    required this.id,

    required this.profileStatus,
    required this.hasCompletedBasicDetails,
    required this.hasCompletedImageUpload,
    required this.hasCompletedPartnerPreference,
    this.privacyEnabled = false,
    this.selfieStatus,
    this.isVerified = false,
    this.isFoundingMember = false,
    this.isPremium = false,
    this.foundingMemberSince,
    this.name,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.maritalStatus,
    this.heightCm,
    this.caste,
    this.motherTongue,
    this.city,
    this.state,
    this.country,
    this.highestEducation,
    this.occupation,
    this.bio,
    this.profileCompletion,
    this.childrenStatus,
    this.emotionalReadiness,
    this.lookingFor,
    this.relationshipTimeline,
    this.languages = const [],
    this.smokingHabit,
    this.drinkingHabit,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawLanguages = json['languages'];
    final privacySettings = json['privacySettings'];

    return User(
      id: json['id'] ?? 0,

      profileStatus: json['profileStatus'] ?? 'INCOMPLETE',
      hasCompletedBasicDetails: json['hasCompletedBasicDetails'] ?? false,
      hasCompletedImageUpload: json['hasCompletedImageUpload'] ?? false,
      hasCompletedPartnerPreference:
          json['hasCompletedPartnerPreference'] ?? false,
      privacyEnabled:
          json['privacyEnabled'] ?? privacySettings?['privacyEnabled'] ?? false,
      selfieStatus: json['selfieStatus'],
      isVerified: json['isVerified'] as bool? ?? false,
      isFoundingMember: json['isFoundingMember'] as bool? ?? false,
      isPremium: json['activeSubscription'] != null || (json['isPremium'] as bool? ?? false),
      foundingMemberSince: json['foundingMemberSince'] != null
          ? DateTime.parse(json['foundingMemberSince'])
          : null,
      name: json['name'],
      email: json['email'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      maritalStatus: json['maritalStatus'],
      heightCm: json['heightCm'],
      caste: json['caste'],
      motherTongue: json['motherTongue'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      highestEducation: json['highestEducation'],
      occupation: json['occupation'],
      bio: json['bio'],
      profileCompletion: json['profileCompletion'],
      childrenStatus: json['childrenStatus'],
      emotionalReadiness: json['emotionalReadiness'],
      lookingFor: json['lookingFor'],
      relationshipTimeline: json['relationshipTimeline'],
      languages: rawLanguages is List
          ? rawLanguages
                .whereType<dynamic>()
                .map((item) => item.toString())
                .where((item) => item.trim().isNotEmpty)
                .toList()
          : rawLanguages is String
          ? rawLanguages
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList()
          : const [],
      smokingHabit: json['smokingHabit'],
      drinkingHabit: json['drinkingHabit'],
    );
  }
}
