class UserImage {
  final int id;
  final String imageUrl;
  final bool isPrimary;
  final int orderIndex;
  final String verificationStatus;

  UserImage({
    required this.id,
    required this.imageUrl,
    required this.isPrimary,
    required this.orderIndex,
    required this.verificationStatus,
  });

  factory UserImage.fromJson(Map<String, dynamic> json) {
    return UserImage(
      id: json['id'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
      orderIndex: json['orderIndex'] as int? ?? 0,
      verificationStatus: json['verificationStatus'] as String? ?? 'Pending',
    );
  }
}

class UserImageResponse {
  final bool success;
  final String message;
  final List<UserImage> data;

  UserImageResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserImageResponse.fromJson(Map<String, dynamic> json) {
    return UserImageResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => UserImage.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
