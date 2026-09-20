import 'package:flutter/material.dart';

enum BurnRateStatus {
  healthy,
  warning,
  exceeded;

  static BurnRateStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'WARNING':
        return BurnRateStatus.warning;
      case 'EXCEEDED':
        return BurnRateStatus.exceeded;
      case 'HEALTHY':
      default:
        return BurnRateStatus.healthy;
    }
  }

  String get label {
    switch (this) {
      case BurnRateStatus.healthy:
        return 'On Track';
      case BurnRateStatus.warning:
        return 'High Burn Rate';
      case BurnRateStatus.exceeded:
        return 'Budget Exceeded';
    }
  }

  Color get color {
    switch (this) {
      case BurnRateStatus.healthy:
        return const Color(0xFF10B981);
      case BurnRateStatus.warning:
        return const Color(0xFFF59E0B);
      case BurnRateStatus.exceeded:
        return const Color(0xFFEF4444);
    }
  }
}

class BudgetEntity {
  final String id;
  final String userId;
  final String categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColorHex;
  final int month;
  final int year;
  final double limitAmount;
  final double spentAmount;
  final double remainingAmount;
  final double spentPercentage;
  final double monthElapsedPercentage;
  final BurnRateStatus burnRateStatus;
  final double projectedSpend;
  final int notifyThresholdPct;
  final DateTime createdAt;

  const BudgetEntity({
    required this.id,
    required this.userId,
    required this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColorHex,
    required this.month,
    required this.year,
    required this.limitAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.spentPercentage,
    required this.monthElapsedPercentage,
    required this.burnRateStatus,
    required this.projectedSpend,
    this.notifyThresholdPct = 80,
    required this.createdAt,
  });

  factory BudgetEntity.fromJson(Map<String, dynamic> json) {
    return BudgetEntity(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      categoryId: json['categoryId'] ?? json['category_id'] ?? '',
      categoryName: json['categoryName'] ?? json['categories']?['name'],
      categoryIcon: json['categoryIcon'] ?? json['categories']?['icon'],
      categoryColorHex: json['categoryColorHex'] ?? json['categories']?['color_hex'],
      month: json['month'] ?? 1,
      year: json['year'] ?? 2026,
      limitAmount: (json['limitAmount'] as num?)?.toDouble() ?? 0.0,
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      spentPercentage: (json['spentPercentage'] as num?)?.toDouble() ?? 0.0,
      monthElapsedPercentage: (json['monthElapsedPercentage'] as num?)?.toDouble() ?? 0.0,
      burnRateStatus: BurnRateStatus.fromString(json['burnRateStatus'] ?? 'HEALTHY'),
      projectedSpend: (json['projectedSpend'] as num?)?.toDouble() ?? 0.0,
      notifyThresholdPct: json['notifyThresholdPct'] ?? 80,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
