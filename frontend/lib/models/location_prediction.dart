class LocationPrediction {
  final String placeId;
  final String name;
  final String description;
  final List<String> types;

  LocationPrediction({
    required this.placeId,
    required this.name,
    required this.description,
    required this.types,
  });

  factory LocationPrediction.fromJson(Map<String, dynamic> json) {
    return LocationPrediction(
      placeId: json['placeId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'description': description,
      'types': types,
    };
  }
}
