import 'package:flutter/material.dart';

enum AiSender {
  user,
  assistant,
}

enum AiInsightType {
  affordabilityCheck,
  burnRateCheck,
  savingsGoalsPace,
  financialSummary,
  generalInsight;

  static AiInsightType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'AFFORDABILITY_CHECK':
        return AiInsightType.affordabilityCheck;
      case 'BURN_RATE_CHECK':
        return AiInsightType.burnRateCheck;
      case 'SAVINGS_GOALS_PACE':
        return AiInsightType.savingsGoalsPace;
      case 'FINANCIAL_SUMMARY':
        return AiInsightType.financialSummary;
      default:
        return AiInsightType.generalInsight;
    }
  }
}

class AffordabilityInsight {
  final String status;
  final double purchaseAmount;
  final double currentLiquidBuffer;
  final double postPurchaseLiquidBuffer;
  final double committedBillsThisMonth;
  final double monthlySavingsTarget;
  final String budgetImpactMessage;

  const AffordabilityInsight({
    required this.status,
    required this.purchaseAmount,
    required this.currentLiquidBuffer,
    required this.postPurchaseLiquidBuffer,
    required this.committedBillsThisMonth,
    required this.monthlySavingsTarget,
    required this.budgetImpactMessage,
  });

  factory AffordabilityInsight.fromJson(Map<String, dynamic> json) {
    return AffordabilityInsight(
      status: json['status']?.toString() ?? 'MODERATE',
      purchaseAmount: (json['purchaseAmount'] as num?)?.toDouble() ?? 0.0,
      currentLiquidBuffer: (json['currentLiquidBuffer'] as num?)?.toDouble() ?? 0.0,
      postPurchaseLiquidBuffer: (json['postPurchaseLiquidBuffer'] as num?)?.toDouble() ?? 0.0,
      committedBillsThisMonth: (json['committedBillsThisMonth'] as num?)?.toDouble() ?? 0.0,
      monthlySavingsTarget: (json['monthlySavingsTarget'] as num?)?.toDouble() ?? 0.0,
      budgetImpactMessage: json['budgetImpactMessage']?.toString() ?? '',
    );
  }
}

class BurnRateInsight {
  final String burnStatus;
  final double totalMonthlyIncome;
  final double totalMonthlyExpense;
  final double burnRatePercentage;
  final int daysPassedInMonth;
  final int totalDaysInMonth;
  final double projectedMonthEndSpend;
  final String topExpenseCategory;

  const BurnRateInsight({
    required this.burnStatus,
    required this.totalMonthlyIncome,
    required this.totalMonthlyExpense,
    required this.burnRatePercentage,
    required this.daysPassedInMonth,
    required this.totalDaysInMonth,
    required this.projectedMonthEndSpend,
    required this.topExpenseCategory,
  });

  factory BurnRateInsight.fromJson(Map<String, dynamic> json) {
    return BurnRateInsight(
      burnStatus: json['burnStatus']?.toString() ?? 'HEALTHY',
      totalMonthlyIncome: (json['totalMonthlyIncome'] as num?)?.toDouble() ?? 0.0,
      totalMonthlyExpense: (json['totalMonthlyExpense'] as num?)?.toDouble() ?? 0.0,
      burnRatePercentage: (json['burnRatePercentage'] as num?)?.toDouble() ?? 0.0,
      daysPassedInMonth: (json['daysPassedInMonth'] as num?)?.toInt() ?? 1,
      totalDaysInMonth: (json['totalDaysInMonth'] as num?)?.toInt() ?? 30,
      projectedMonthEndSpend: (json['projectedMonthEndSpend'] as num?)?.toDouble() ?? 0.0,
      topExpenseCategory: json['topExpenseCategory']?.toString() ?? 'General',
    );
  }
}

class SavingsGoalsInsight {
  final int goalCount;
  final List<String> activeGoalNames;
  final double totalSaved;
  final double totalTarget;
  final double overallProgressPercentage;
  final double requiredDailySavings;
  final double requiredMonthlySavings;

  const SavingsGoalsInsight({
    required this.goalCount,
    required this.activeGoalNames,
    required this.totalSaved,
    required this.totalTarget,
    required this.overallProgressPercentage,
    required this.requiredDailySavings,
    required this.requiredMonthlySavings,
  });

  factory SavingsGoalsInsight.fromJson(Map<String, dynamic> json) {
    return SavingsGoalsInsight(
      goalCount: (json['goalCount'] as num?)?.toInt() ?? 0,
      activeGoalNames: (json['activeGoalNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      totalSaved: (json['totalSaved'] as num?)?.toDouble() ?? 0.0,
      totalTarget: (json['totalTarget'] as num?)?.toDouble() ?? 0.0,
      overallProgressPercentage: (json['overallProgressPercentage'] as num?)?.toDouble() ?? 0.0,
      requiredDailySavings: (json['requiredDailySavings'] as num?)?.toDouble() ?? 0.0,
      requiredMonthlySavings: (json['requiredMonthlySavings'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FinancialSummaryInsight {
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final double liquidBuffer;
  final double monthlySavingsRate;

  const FinancialSummaryInsight({
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.liquidBuffer,
    required this.monthlySavingsRate,
  });

  factory FinancialSummaryInsight.fromJson(Map<String, dynamic> json) {
    return FinancialSummaryInsight(
      netWorth: (json['netWorth'] as num?)?.toDouble() ?? 0.0,
      totalAssets: (json['totalAssets'] as num?)?.toDouble() ?? 0.0,
      totalLiabilities: (json['totalLiabilities'] as num?)?.toDouble() ?? 0.0,
      liquidBuffer: (json['liquidBuffer'] as num?)?.toDouble() ?? 0.0,
      monthlySavingsRate: (json['monthlySavingsRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AiStructuredInsightEntity {
  final AiInsightType type;
  final String title;
  final String summary;
  final Color statusColor;
  final AffordabilityInsight? affordability;
  final BurnRateInsight? burnRate;
  final SavingsGoalsInsight? savingsGoals;
  final FinancialSummaryInsight? financialSummary;

  const AiStructuredInsightEntity({
    required this.type,
    required this.title,
    required this.summary,
    required this.statusColor,
    this.affordability,
    this.burnRate,
    this.savingsGoals,
    this.financialSummary,
  });

  factory AiStructuredInsightEntity.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? '';
    final type = AiInsightType.fromString(typeStr);
    final colorHex = json['statusColor']?.toString() ?? '#7C5CFF';
    final parsedColor = Color(int.tryParse(colorHex.replaceFirst('#', '0xFF')) ?? 0xFF7C5CFF);

    return AiStructuredInsightEntity(
      type: type,
      title: json['title']?.toString() ?? 'FINANCIAL INSIGHT',
      summary: json['summary']?.toString() ?? '',
      statusColor: parsedColor,
      affordability: json['affordability'] != null ? AffordabilityInsight.fromJson(json['affordability']) : null,
      burnRate: json['burnRate'] != null ? BurnRateInsight.fromJson(json['burnRate']) : null,
      savingsGoals: json['savingsGoals'] != null ? SavingsGoalsInsight.fromJson(json['savingsGoals']) : null,
      financialSummary: json['financialSummary'] != null ? FinancialSummaryInsight.fromJson(json['financialSummary']) : null,
    );
  }
}

class AiMessageEntity {
  final String id;
  final String text;
  final AiSender sender;
  final DateTime timestamp;
  final List<String> toolsUsed;
  final AiStructuredInsightEntity? structuredInsight;

  const AiMessageEntity({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.toolsUsed = const [],
    this.structuredInsight,
  });

  bool get isUser => sender == AiSender.user;

  factory AiMessageEntity.fromJson(Map<String, dynamic> json, {required String id, required AiSender sender}) {
    return AiMessageEntity(
      id: id,
      text: json['message']?.toString() ?? '',
      sender: sender,
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) ?? DateTime.now() : DateTime.now(),
      toolsUsed: (json['toolsUsed'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      structuredInsight: json['structuredInsight'] != null
          ? AiStructuredInsightEntity.fromJson(json['structuredInsight'])
          : null,
    );
  }
}
