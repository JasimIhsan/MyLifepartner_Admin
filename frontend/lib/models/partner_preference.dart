class PartnerPreference {
  final int? ageFrom;
  final int? ageTo;
  final List<String> maritalStatus;
  final List<String> motherTongue;

  const PartnerPreference({
    this.ageFrom,
    this.ageTo,
    this.maritalStatus = const [],
    this.motherTongue = const [],
  });

  factory PartnerPreference.fromJson(Map<String, dynamic> json) {
    return PartnerPreference(
      ageFrom: _asInt(json['ageFrom']),
      ageTo: _asInt(json['ageTo']),
      maritalStatus: _asStringList(json['maritalStatus']),
      motherTongue: _asStringList(json['motherTongue']),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }
}
