class LocationDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final String? country;
  final String? countryCode;
  final String? state;
  final String? stateCode;
  final String? city;
  final double? latitude;
  final double? longitude;
  final List<String> types;
  final String?
  source; // "current_location", "autocomplete", "existing_profile"

  LocationDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    this.country,
    this.countryCode,
    this.state,
    this.stateCode,
    this.city,
    this.latitude,
    this.longitude,
    required this.types,
    this.source,
  });

  factory LocationDetails.fromJson(Map<String, dynamic> json) {
    return LocationDetails(
      placeId: json['placeId'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      country: json['country'],
      countryCode: json['countryCode'],
      state: json['state'],
      stateCode: json['stateCode'],
      city: json['city'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      types: List<String>.from(json['types'] ?? []),
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'formattedAddress': formattedAddress,
      'country': country,
      'countryCode': countryCode,
      'state': state,
      'stateCode': stateCode,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'types': types,
      'source': source,
    };
  }
}
