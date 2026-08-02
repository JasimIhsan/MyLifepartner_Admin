class DiscoveryFilter {
  int? ageFrom;
  int? ageTo;
  List<String> languages;
  List<String> maritalStatuses;
  String? childrenStatus;
  List<String> smokingStatuses;
  List<String> drinkingStatuses;
  bool verifiedOnly;
  String? searchQuery;

  DiscoveryFilter({
    this.ageFrom,
    this.ageTo,
    this.languages = const [],
    this.maritalStatuses = const [],
    this.childrenStatus,
    this.smokingStatuses = const [],
    this.drinkingStatuses = const [],
    this.verifiedOnly = false,
    this.searchQuery,
  });

  DiscoveryFilter copyWith({
    int? ageFrom,
    int? ageTo,
    List<String>? languages,
    List<String>? maritalStatuses,
    String? childrenStatus,
    List<String>? smokingStatuses,
    List<String>? drinkingStatuses,
    bool? verifiedOnly,
    String? searchQuery,
  }) {
    return DiscoveryFilter(
      ageFrom: ageFrom ?? this.ageFrom,
      ageTo: ageTo ?? this.ageTo,
      languages: languages ?? List.from(this.languages),
      maritalStatuses: maritalStatuses ?? List.from(this.maritalStatuses),
      childrenStatus: childrenStatus ?? this.childrenStatus,
      smokingStatuses: smokingStatuses ?? List.from(this.smokingStatuses),
      drinkingStatuses: drinkingStatuses ?? List.from(this.drinkingStatuses),
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      if (ageFrom != null) 'ageFrom': ageFrom,
      if (ageTo != null) 'ageTo': ageTo,
      if (languages.isNotEmpty) 'languages': languages.join(','),
      if (maritalStatuses.isNotEmpty) 'maritalStatus': maritalStatuses.join(','),
      if (childrenStatus != null) 'childrenStatus': childrenStatus,
      if (smokingStatuses.isNotEmpty) 'smoking': smokingStatuses.join(','),
      if (drinkingStatuses.isNotEmpty) 'drinking': drinkingStatuses.join(','),
      if (verifiedOnly) 'verifiedOnly': 'true',
      if (searchQuery != null && searchQuery!.isNotEmpty) 'search': searchQuery,
    };
    return map;
  }
}
