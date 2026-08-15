class TransactionHistory {
  final int id;
  final int userId;
  final int? planId;
  final String status;
  final double? amount;
  final String? currency;
  final String? revenueCatEventId;
  final String? originalTransactionId;
  final String? store;
  final String? environment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? planName;
  final double? planPrice;

  TransactionHistory({
    required this.id,
    required this.userId,
    this.planId,
    required this.status,
    this.amount,
    this.currency,
    this.revenueCatEventId,
    this.originalTransactionId,
    this.store,
    this.environment,
    required this.createdAt,
    required this.updatedAt,
    this.planName,
    this.planPrice,
  });

  factory TransactionHistory.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>?;
    return TransactionHistory(
      id: json['id'],
      userId: json['userId'],
      planId: json['planId'],
      status: json['status'],
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : null,
      currency: json['currency'],
      revenueCatEventId: json['revenueCatEventId'],
      originalTransactionId: json['originalTransactionId'],
      store: json['store'],
      environment: json['environment'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      planName: plan?['name'],
      planPrice: plan?['price'] != null
          ? (plan?['price'] as num).toDouble()
          : null,
    );
  }
}
