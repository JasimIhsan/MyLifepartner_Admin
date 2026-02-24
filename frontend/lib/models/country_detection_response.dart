class CountryDetectionResponse {
  final bool success;
  final String message;
  final String? ip;
  final String? countryCode;

  CountryDetectionResponse({
    required this.success,
    required this.message,
    this.ip,
    this.countryCode,
  });

  factory CountryDetectionResponse.fromJson(Map<String, dynamic> json) {
    return CountryDetectionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      ip: json['data'] != null ? json['data']['ip'] : null,
      countryCode: json['data'] != null ? json['data']['countryCode'] : null,
    );
  }
}
