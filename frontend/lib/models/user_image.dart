class UserImage {
  final int id;
  final int imageId;
  final String imageUrl;
  final String presignedImageUrl;
  final bool isPrimary;
  final int orderIndex;
  final String verificationStatus;

  UserImage({
    required this.id,
    required this.imageId,
    required this.imageUrl,
    required this.presignedImageUrl,
    required this.isPrimary,
    required this.orderIndex,
    required this.verificationStatus,
  });

  factory UserImage.fromJson(Map<String, dynamic> json) {
    final parsedImageId = json['imageId'] as int? ?? json['id'] as int? ?? 0;
    final parsedImageUrl =
        json['presignedImageUrl'] as String? ??
        json['imageUrl'] as String? ??
        json['url'] as String? ??
        '';

    return UserImage(
      id: parsedImageId,
      imageId: parsedImageId,
      imageUrl: parsedImageUrl,
      presignedImageUrl: parsedImageUrl,
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
