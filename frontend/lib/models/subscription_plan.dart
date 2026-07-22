import 'feature_key.dart';

class Feature {
  final int id;
  final FeatureKey key;
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
      id: json['id'] ?? 0,
      key: FeatureKey.fromString(json['key']),
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class PlanFeature {
  final int id;
  final String limit;
  final String? description;
  final Feature feature;

  PlanFeature({
    required this.id,
    required this.limit,
    this.description,
    required this.feature,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      id: json['id'] ?? 0,
      limit: json['limit']?.toString() ?? '0',
      description: json['description'],
      feature: json['feature'] != null
          ? Feature.fromJson(json['feature'])
          : Feature(
              id: 0,
              key: json['featureKey'] ?? 'unknown',
              name: json['featureKey'] ?? 'Unknown',
            ),
    );
  }
}

class SubscriptionPlan {
  final int id;
  final String name;
  final int price; // backend price (paise)
  final int durationDays;
  final bool isActive;
  final bool isMostPopular;
  final String? identifier;
  final List<PlanFeature> features;

  // 🔥 NEW (RevenueCat overrides)
  final String? rcDisplayPrice;
  final double? rcPrice;
  final String? rcDurationTitle;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.isActive,
    required this.isMostPopular,
    this.identifier,
    required this.features,
    this.rcDisplayPrice,
    this.rcPrice,
    this.rcDurationTitle,
  });
  SubscriptionPlan copyWith({
    String? name,
    int? price,
    int? durationDays,
    bool? isActive,
    bool? isMostPopular,
    String? identifier,
    List<PlanFeature>? features,
    String? rcDisplayPrice,
    double? rcPrice,
    String? rcDurationTitle,
  }) {
    return SubscriptionPlan(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      durationDays: durationDays ?? this.durationDays,
      isActive: isActive ?? this.isActive,
      isMostPopular: isMostPopular ?? this.isMostPopular,
      identifier: identifier ?? this.identifier,
      features: features ?? this.features,
      rcDisplayPrice: rcDisplayPrice ?? this.rcDisplayPrice,
      rcPrice: rcPrice ?? this.rcPrice,
      rcDurationTitle: rcDurationTitle ?? this.rcDurationTitle,
    );
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      price: json['price'] ?? 0,
      durationDays: json['durationDays'] ?? 0,
      isActive: json['isActive'] ?? true,
      isMostPopular: json['isMostPopular'] ?? false,
      identifier: json['storeProductId'],
      features:
          (json['features'] as List?)
              ?.map((e) => PlanFeature.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Helper getter to format price from paise to readable string, assuming USD/INR formatting
  String get displayPrice {
    if (rcDisplayPrice != null) return rcDisplayPrice!;

    final amount = price / 100;
    return '₹${amount.toStringAsFixed(0)}';
  }

  /// Helper to get a simple string list of feature descriptions for the UI
  List<String> get featureDescriptions {
    return features
        .map(
          (pf) => pf.description ?? pf.feature.description ?? pf.feature.name,
        )
        .toList();
  }
}

class UserSubscription {
  final int id;
  final int planId;
  final SubscriptionPlan? plan;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? message;
  final bool willRenew;

  UserSubscription({
    required this.id,
    required this.planId,
    this.plan,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.message,
    this.willRenew = true,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      planId: json['planId'],
      plan: json['plan'] != null
          ? SubscriptionPlan.fromJson(json['plan'])
          : null,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'],
      message: json['message'],
      willRenew: json['willRenew'] ?? true,
    );
  }

  bool get isActive => status == 'ACTIVE' && endDate.isAfter(DateTime.now());
}
