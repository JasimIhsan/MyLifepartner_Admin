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
  final String token;
  final User? user;

  VerifyOtpResponse({
    required this.success,
    required this.message,
    required this.token,
    this.user,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'] ?? '',
      user: json['data'] != null && json['data']['user'] != null
          ? User.fromJson(json['data']['user'])
          : null,
    );
  }
}

class User {
  final int id;
  final String mobileNumber;
  final bool isProfileCompleted;
  final bool hasCompletedImageUpload;
  final String? selfieStatus;

  User({
    required this.id,
    required this.mobileNumber,
    required this.isProfileCompleted,
    required this.hasCompletedImageUpload,
    this.selfieStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      mobileNumber: json['mobileNumber'] ?? '',
      isProfileCompleted: json['isProfileCompleted'] ?? false,
      hasCompletedImageUpload: json['hasCompletedImageUpload'] ?? false,
      selfieStatus: json['selfieStatus'],
    );
  }
}
