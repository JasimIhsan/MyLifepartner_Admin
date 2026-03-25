class Feature {
  final int id;
  final String key;
  final String name;
  final String? description;

  Feature({
    required this.id,
    required this.key,
    required this.name,
    this.description,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      id: json['id'],
      key: json['key'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class PlanFeature {
  final int id;
  final String limit;
  final Feature feature;

  PlanFeature({
    required this.id,
    required this.limit,
    required this.feature,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      id: json['id'],
      limit: json['limit'],
      feature: Feature.fromJson(json['feature']),
    );
  }
}

class SubscriptionPlan {
  final int id;
  final String name;
  final int price; // in paise
  final int durationDays;
  final bool isActive;
  final List<PlanFeature> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.isActive,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      durationDays: json['durationDays'],
      isActive: json['isActive'] ?? true,
      features: (json['features'] as List?)
              ?.map((e) => PlanFeature.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Helper getter to format price from paise to readable string, assuming USD/INR formatting
  String get displayPrice {
    final amount = price / 100;
    // You can customize currency symbol based on locale, assuming INR here since it's paise
    return '₹${amount.toStringAsFixed(0)}';
  }

  /// Helper to get a simple string list of feature descriptions for the UI
  List<String> get featureDescriptions {
    return features.map((pf) => pf.feature.name).toList();
  }
}

class UserSubscription {
  final int id;
  final int planId;
  final SubscriptionPlan? plan;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  UserSubscription({
    required this.id,
    required this.planId,
    this.plan,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      planId: json['planId'],
      plan: json['plan'] != null ? SubscriptionPlan.fromJson(json['plan']) : null,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'],
    );
  }

  bool get isActive => status == 'ACTIVE' && endDate.isAfter(DateTime.now());
}
