class GuideItem {
  final int id;
  final String question;
  final String answer;
  final int categoryId;
  final List<String> bullets;
  final int displayOrder;

  const GuideItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.categoryId,
    required this.bullets,
    required this.displayOrder,
  });

  factory GuideItem.fromJson(Map<String, dynamic> json) {
    return GuideItem(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      categoryId: json['categoryId'] as int,
      bullets: (json['bullets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}
