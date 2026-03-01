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

  User({
    required this.id,
    required this.mobileNumber,
    required this.profileStatus,
    required this.hasCompletedImageUpload,
    this.selfieStatus,
    this.name,
    this.email,
    this.isEmailVerified,
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
    );
  }
}
