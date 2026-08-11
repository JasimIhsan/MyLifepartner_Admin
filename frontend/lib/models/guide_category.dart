class GuideCategory {
  final int id;
  final String name;
  final int displayOrder;
  final int guideCount;

  const GuideCategory({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.guideCount,
  });

  factory GuideCategory.fromJson(Map<String, dynamic> json) {
    return GuideCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      displayOrder: json['displayOrder'] as int? ?? 0,
      guideCount: json['guideCount'] as int? ?? 0,
    );
  }
}
