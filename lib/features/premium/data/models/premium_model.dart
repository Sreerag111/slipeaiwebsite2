import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumModel {
  final bool isPremium;
  final String? planType; // 'monthly' or legacy ID 'max' (yearly)
  final DateTime? expirationDate;

  const PremiumModel({
    required this.isPremium,
    this.planType,
    this.expirationDate,
  });

  factory PremiumModel.fromJson(Map<String, dynamic> json) {
    final currentPeriodEnd = json['currentPeriodEnd'];
    return PremiumModel(
      isPremium: json['isPremium'] == true,
      planType: json['planId'] as String?,
      expirationDate: currentPeriodEnd is Timestamp
          ? currentPeriodEnd.toDate()
          : currentPeriodEnd is String
              ? DateTime.tryParse(currentPeriodEnd)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'isPremium': isPremium,
        'planId': planType,
        'currentPeriodEnd': expirationDate,
      };

  PremiumModel copyWith({
    bool? isPremium,
    String? planType,
    DateTime? expirationDate,
  }) {
    return PremiumModel(
      isPremium: isPremium ?? this.isPremium,
      planType: planType ?? this.planType,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}
