import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum AccountType {
  cash,
  bank,
  creditCard,
  digitalWallet,
  other;

  static AccountType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'cash':
        return AccountType.cash;
      case 'bank':
        return AccountType.bank;
      case 'credit_card':
        return AccountType.creditCard;
      case 'digital_wallet':
        return AccountType.digitalWallet;
      default:
        return AccountType.other;
    }
  }

  String toApiString() {
    switch (this) {
      case AccountType.cash:
        return 'cash';
      case AccountType.bank:
        return 'bank';
      case AccountType.creditCard:
        return 'credit_card';
      case AccountType.digitalWallet:
        return 'digital_wallet';
      case AccountType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.digitalWallet:
        return 'Digital Wallet';
      case AccountType.other:
        return 'Other Account';
    }
  }

  IconData get iconData {
    switch (this) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.cash:
        return Icons.money;
      case AccountType.digitalWallet:
        return Icons.phone_android;
      case AccountType.other:
        return Icons.account_balance_wallet;
    }
  }

  Color get color {
    switch (this) {
      case AccountType.bank:
        return AppColors.primary;
      case AccountType.creditCard:
        return AppColors.expense;
      case AccountType.cash:
        return AppColors.income;
      case AccountType.digitalWallet:
        return AppColors.info;
      case AccountType.other:
        return AppColors.warning;
    }
  }
}

class AccountEntity {
  final String id;
  final String userId;
  final String name;
  final AccountType accountType;
  final String currency;
  final double currentBalance;
  final double? creditLimit;
  final int? billingCycleDay;
  final bool isArchived;
  final DateTime createdAt;

  const AccountEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.accountType,
    required this.currency,
    required this.currentBalance,
    this.creditLimit,
    this.billingCycleDay,
    this.isArchived = false,
    required this.createdAt,
  });

  factory AccountEntity.fromJson(Map<String, dynamic> json) {
    return AccountEntity(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      name: json['name'] ?? '',
      accountType: AccountType.fromString(json['accountType'] ?? json['account_type'] ?? 'bank'),
      currency: json['currency'] ?? 'INR',
      currentBalance: (json['currentBalance'] ?? json['current_balance'] ?? 0.0).toDouble(),
      creditLimit: json['creditLimit'] != null
          ? (json['creditLimit'] as num).toDouble()
          : (json['credit_limit'] != null ? (json['credit_limit'] as num).toDouble() : null),
      billingCycleDay: json['billingCycleDay'] ?? json['billing_cycle_day'],
      isArchived: json['isArchived'] ?? json['is_archived'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'accountType': accountType.toApiString(),
      'currency': currency,
      'currentBalance': currentBalance,
      'creditLimit': creditLimit,
      'billingCycleDay': billingCycleDay,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AccountsSummaryEntity {
  final double totalNetWorth;
  final double totalAssets;
  final double totalLiabilities;
  final int accountCount;
  final Map<String, double> accountsByType;

  const AccountsSummaryEntity({
    required this.totalNetWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.accountCount,
    required this.accountsByType,
  });

  factory AccountsSummaryEntity.fromJson(Map<String, dynamic> json) {
    final rawByType = json['accountsByType'] as Map<String, dynamic>? ?? {};
    final byType = rawByType.map((k, v) => MapEntry(k, (v as num).toDouble()));

    return AccountsSummaryEntity(
      totalNetWorth: (json['totalNetWorth'] ?? 0.0).toDouble(),
      totalAssets: (json['totalAssets'] ?? 0.0).toDouble(),
      totalLiabilities: (json['totalLiabilities'] ?? 0.0).toDouble(),
      accountCount: json['accountCount'] ?? 0,
      accountsByType: byType,
    );
  }
}
