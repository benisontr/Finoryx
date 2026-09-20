import 'package:flutter_test/flutter_test.dart';
import 'package:finoryx_mobile/core/utils/app_formatters.dart';
import 'package:finoryx_mobile/features/ai_assistant/domain/ai_message_entity.dart';
import 'package:finoryx_mobile/features/goals/domain/goal_entity.dart';

void main() {
  group('AppFormatters Unit Tests', () {
    test('Resolves currency symbols accurately', () {
      expect(AppFormatters.symbolForCurrency('USD'), equals('\$'));
      expect(AppFormatters.symbolForCurrency('EUR'), equals('€'));
      expect(AppFormatters.symbolForCurrency('GBP'), equals('£'));
      expect(AppFormatters.symbolForCurrency('INR'), equals('₹'));
      expect(AppFormatters.symbolForCurrency(null), equals('₹'));
    });

    test('Formats currency amounts correctly with precision and commas', () {
      final formatted = AppFormatters.currency(150000.50, symbol: '₹');
      expect(formatted, contains('150,000.50'));
      expect(formatted, startsWith('₹'));
    });

    test('Formats percentage strings', () {
      expect(AppFormatters.percentage(75.456), equals('75.5%'));
      expect(AppFormatters.percentage(100.0), equals('100.0%'));
    });
  });

  group('Goal Pace Status Tests', () {
    test('Calculates pace status correctly', () {
      final completedGoal = GoalEntity.fromJson({
        'id': 'g-1',
        'userId': 'u-1',
        'name': 'Car Fund',
        'targetAmount': 500000.0,
        'currentAmount': 500000.0,
        'remainingAmount': 0.0,
        'progressPercentage': 100.0,
        'targetDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'daysRemaining': 30,
        'paceStatus': 'COMPLETED',
        'expectedPaceAmount': 500000.0,
        'paceDifference': 0.0,
        'requiredMonthlySavings': 0.0,
        'requiredWeeklySavings': 0.0,
        'requiredDailySavings': 0.0,
        'isCompleted': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      expect(completedGoal.paceStatus, equals(GoalPaceStatus.completed));
      expect(completedGoal.progressPercentage, equals(100.0));
      expect(completedGoal.remainingAmount, equals(0.0));
    });
  });

  group('AI Entity Deserialization Tests', () {
    test('Deserializes Affordability Structured Insight payload', () {
      final json = {
        'type': 'AFFORDABILITY_CHECK',
        'title': 'AFFORDABILITY DECISION',
        'summary': 'Safe purchase evaluation',
        'statusColor': '#10B981',
        'affordability': {
          'status': 'COMFORTABLE',
          'purchaseAmount': 12000.0,
          'currentLiquidBuffer': 50000.0,
          'postPurchaseLiquidBuffer': 38000.0,
          'committedBillsThisMonth': 5000.0,
          'monthlySavingsTarget': 2000.0,
          'budgetImpactMessage': 'You can comfortably afford this purchase.',
        },
      };

      final insight = AiStructuredInsightEntity.fromJson(json);
      expect(insight.type, equals(AiInsightType.affordabilityCheck));
      expect(insight.affordability, isNotNull);
      expect(insight.affordability?.status, equals('COMFORTABLE'));
      expect(insight.affordability?.purchaseAmount, equals(12000.0));
      expect(insight.affordability?.postPurchaseLiquidBuffer, equals(38000.0));
    });

    test('Deserializes Burn Rate Structured Insight payload', () {
      final json = {
        'type': 'BURN_RATE_CHECK',
        'title': 'BURN RATE ANALYSIS',
        'summary': 'Pacing warning',
        'statusColor': '#EF4444',
        'burnRate': {
          'burnStatus': 'WARNING',
          'totalMonthlyIncome': 80000.0,
          'totalMonthlyExpense': 65000.0,
          'burnRatePercentage': 81.25,
          'daysPassedInMonth': 15,
          'totalDaysInMonth': 30,
          'projectedMonthEndSpend': 130000.0,
          'topExpenseCategory': 'Electronics & Tech',
        },
      };

      final insight = AiStructuredInsightEntity.fromJson(json);
      expect(insight.type, equals(AiInsightType.burnRateCheck));
      expect(insight.burnRate, isNotNull);
      expect(insight.burnRate?.burnStatus, equals('WARNING'));
      expect(insight.burnRate?.topExpenseCategory, equals('Electronics & Tech'));
    });
  });
}
