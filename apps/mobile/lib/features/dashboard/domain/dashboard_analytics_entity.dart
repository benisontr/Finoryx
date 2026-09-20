import '../../budgets/domain/budget_entity.dart';
import '../../goals/domain/goal_entity.dart';

class CategorySpendingItem {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;
  final double amount;
  final double percentage;

  const CategorySpendingItem({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    required this.amount,
    required this.percentage,
  });

  factory CategorySpendingItem.fromJson(Map<String, dynamic> json) {
    return CategorySpendingItem(
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? 'Uncategorized',
      categoryIcon: json['categoryIcon'] as String? ?? 'help_outline',
      categoryColorHex: json['categoryColorHex'] as String? ?? '#94A3B8',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CashFlowTrendPoint {
  final int month;
  final int year;
  final String label;
  final double income;
  final double expense;
  final double netCashFlow;

  const CashFlowTrendPoint({
    required this.month,
    required this.year,
    required this.label,
    required this.income,
    required this.expense,
    required this.netCashFlow,
  });

  factory CashFlowTrendPoint.fromJson(Map<String, dynamic> json) {
    return CashFlowTrendPoint(
      month: (json['month'] as num?)?.toInt() ?? 1,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      label: json['label'] as String? ?? '',
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      netCashFlow: (json['netCashFlow'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardNetWorth {
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final int accountsCount;

  const DashboardNetWorth({
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.accountsCount,
  });

  factory DashboardNetWorth.fromJson(Map<String, dynamic> json) {
    return DashboardNetWorth(
      netWorth: (json['netWorth'] as num?)?.toDouble() ?? 0.0,
      totalAssets: (json['totalAssets'] as num?)?.toDouble() ?? 0.0,
      totalLiabilities: (json['totalLiabilities'] as num?)?.toDouble() ?? 0.0,
      accountsCount: (json['accountsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardCashFlow {
  final int month;
  final int year;
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;
  final double savingsRate;

  const DashboardCashFlow({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.savingsRate,
  });

  factory DashboardCashFlow.fromJson(Map<String, dynamic> json) {
    return DashboardCashFlow(
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      netCashFlow: (json['netCashFlow'] as num?)?.toDouble() ?? 0.0,
      savingsRate: (json['savingsRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardBudgetsSummary {
  final double totalBudgetLimit;
  final double totalBudgetSpent;
  final double overallPercentage;
  final int warningCount;
  final int exceededCount;
  final List<BudgetEntity> criticalBudgets;

  const DashboardBudgetsSummary({
    required this.totalBudgetLimit,
    required this.totalBudgetSpent,
    required this.overallPercentage,
    required this.warningCount,
    required this.exceededCount,
    required this.criticalBudgets,
  });

  factory DashboardBudgetsSummary.fromJson(Map<String, dynamic> json) {
    final critJson = (json['criticalBudgets'] as List<dynamic>?) ?? [];
    return DashboardBudgetsSummary(
      totalBudgetLimit: (json['totalBudgetLimit'] as num?)?.toDouble() ?? 0.0,
      totalBudgetSpent: (json['totalBudgetSpent'] as num?)?.toDouble() ?? 0.0,
      overallPercentage: (json['overallPercentage'] as num?)?.toDouble() ?? 0.0,
      warningCount: (json['warningCount'] as num?)?.toInt() ?? 0,
      exceededCount: (json['exceededCount'] as num?)?.toInt() ?? 0,
      criticalBudgets: critJson
          .map((item) => BudgetEntity.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardGoalsSummary {
  final double totalTarget;
  final double totalSaved;
  final double overallProgress;
  final int activeCount;
  final int completedCount;
  final GoalEntity? nearestGoal;

  const DashboardGoalsSummary({
    required this.totalTarget,
    required this.totalSaved,
    required this.overallProgress,
    required this.activeCount,
    required this.completedCount,
    this.nearestGoal,
  });

  factory DashboardGoalsSummary.fromJson(Map<String, dynamic> json) {
    return DashboardGoalsSummary(
      totalTarget: (json['totalTarget'] as num?)?.toDouble() ?? 0.0,
      totalSaved: (json['totalSaved'] as num?)?.toDouble() ?? 0.0,
      overallProgress: (json['overallProgress'] as num?)?.toDouble() ?? 0.0,
      activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      nearestGoal: json['nearestGoal'] != null
          ? GoalEntity.fromJson(json['nearestGoal'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DashboardAnalyticsEntity {
  final DashboardNetWorth netWorth;
  final DashboardCashFlow cashFlow;
  final List<CategorySpendingItem> spendingBreakdown;
  final DashboardBudgetsSummary budgetsSummary;
  final DashboardGoalsSummary goalsSummary;
  final List<CashFlowTrendPoint> cashFlowTrends;

  const DashboardAnalyticsEntity({
    required this.netWorth,
    required this.cashFlow,
    required this.spendingBreakdown,
    required this.budgetsSummary,
    required this.goalsSummary,
    required this.cashFlowTrends,
  });

  factory DashboardAnalyticsEntity.fromJson(Map<String, dynamic> json) {
    final breakdownJson = (json['spendingBreakdown'] as List<dynamic>?) ?? [];
    final trendsJson = (json['cashFlowTrends'] as List<dynamic>?) ?? [];

    return DashboardAnalyticsEntity(
      netWorth: DashboardNetWorth.fromJson(
        (json['netWorth'] as Map<String, dynamic>?) ?? {},
      ),
      cashFlow: DashboardCashFlow.fromJson(
        (json['cashFlow'] as Map<String, dynamic>?) ?? {},
      ),
      spendingBreakdown: breakdownJson
          .map((item) => CategorySpendingItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      budgetsSummary: DashboardBudgetsSummary.fromJson(
        (json['budgetsSummary'] as Map<String, dynamic>?) ?? {},
      ),
      goalsSummary: DashboardGoalsSummary.fromJson(
        (json['goalsSummary'] as Map<String, dynamic>?) ?? {},
      ),
      cashFlowTrends: trendsJson
          .map((item) => CashFlowTrendPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
