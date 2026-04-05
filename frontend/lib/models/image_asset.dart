class ImageAsset {
  final int id;
  final String section;
  final String title;
  final String imageUrl;
  final String? altText;
  final String? redirectUrl;
  final int displayOrder;
  final bool isActive;

  ImageAsset({
    required this.id,
    required this.section,
    required this.title,
    required this.imageUrl,
    this.altText,
    this.redirectUrl,
    required this.displayOrder,
    required this.isActive,
  });

  factory ImageAsset.fromJson(Map<String, dynamic> json) {
    return ImageAsset(
      id: json['id'],
      section: json['section'],
      title: json['title'],
      imageUrl: json['imageUrl'] ?? '',
      altText: json['altText'],
      redirectUrl: json['redirectUrl'],
      displayOrder: json['displayOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section': section,
      'title': title,
      'imageUrl': imageUrl,
      'altText': altText,
      'redirectUrl': redirectUrl,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }
}
