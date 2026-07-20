class OnboardingStatus {
  final int id;
  final bool hasCompletedBasicDetails;
  final bool hasCompletedPartnerPreference;
  final String profileStatus;
  final bool hasCompletedImageUpload;
  final String? selfieStatus;

  const OnboardingStatus({
    required this.id,
    required this.hasCompletedBasicDetails,
    required this.hasCompletedPartnerPreference,
    required this.profileStatus,
    required this.hasCompletedImageUpload,
    required this.selfieStatus,
  });

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(
      id: json['id'] ?? 0,
      hasCompletedBasicDetails: json['hasCompletedBasicDetails'] ?? false,
      hasCompletedPartnerPreference:
          json['hasCompletedPartnerPreference'] ?? false,
      profileStatus: json['profileStatus'] ?? 'INCOMPLETE',
      hasCompletedImageUpload: json['hasCompletedImageUpload'] ?? false,
      selfieStatus: json['selfieStatus'],
    );
  }
}

class OnboardingStatusResponse {
  final bool success;
  final String message;
  final OnboardingStatus? data;

  const OnboardingStatusResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OnboardingStatusResponse.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? OnboardingStatus.fromJson(json['data'])
          : null,
    );
  }
}
