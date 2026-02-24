class ProfileSection {
  final int id;
  final String key;
  final String title;
  final int orderNo;
  final bool isPrimary;

  ProfileSection({
    required this.id,
    required this.key,
    required this.title,
    required this.orderNo,
    this.isPrimary = false,
  });

  factory ProfileSection.fromJson(Map<String, dynamic> json) {
    return ProfileSection(
      id: json['id'],
      key: json['key'],
      title: json['title'],
      orderNo: json['orderNo'] ?? 0,
      isPrimary: json['isPrimary'] ?? false,
    );
  }
}
