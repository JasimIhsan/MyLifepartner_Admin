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

class VerifyOtpResponse {
  final bool success;
  final String message;
  final String accessToken;
  final String refreshToken;
  final User? user;

  VerifyOtpResponse({
    required this.success,
    required this.message,
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
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
  final String mobileNumber;
  final String profileStatus;
  final bool hasCompletedImageUpload;
  final String? selfieStatus;
  final String? name;
  final String? email;
  final bool? isEmailVerified;

  // Profile demographics
  final String? gender;
  final DateTime? dateOfBirth;
  final String? maritalStatus;
  final int? heightCm;
  final String? religion;
  final String? caste;
  final String? motherTongue;
  final String? city;
  final String? state;
  final String? country;
  final String? highestEducation;
  final String? occupation;
  final int? annualIncome;
  final String? bio;
  final int? profileCompletion;

  User({
    required this.id,
    required this.mobileNumber,
    required this.profileStatus,
    required this.hasCompletedImageUpload,
    this.selfieStatus,
    this.name,
    this.email,
    this.isEmailVerified,
    this.gender,
    this.dateOfBirth,
    this.maritalStatus,
    this.heightCm,
    this.religion,
    this.caste,
    this.motherTongue,
    this.city,
    this.state,
    this.country,
    this.highestEducation,
    this.occupation,
    this.annualIncome,
    this.bio,
    this.profileCompletion,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      mobileNumber: json['mobileNumber'] ?? '',
      profileStatus: json['profileStatus'] ?? 'INCOMPLETE',
      hasCompletedImageUpload: json['hasCompletedImageUpload'] ?? false,
      selfieStatus: json['selfieStatus'],
      name: json['name'],
      email: json['email'],
      isEmailVerified: json['isEmailVerified'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      maritalStatus: json['maritalStatus'],
      heightCm: json['heightCm'],
      religion: json['religion'],
      caste: json['caste'],
      motherTongue: json['motherTongue'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      highestEducation: json['highestEducation'],
      occupation: json['occupation'],
      annualIncome: json['annualIncome'],
      bio: json['bio'],
      profileCompletion: json['profileCompletion'],
    );
  }
}
