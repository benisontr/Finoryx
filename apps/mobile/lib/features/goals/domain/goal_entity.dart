import 'package:flutter/material.dart';

enum GoalPaceStatus {
  completed,
  ahead,
  onTrack,
  behind,
  overdue;

  static GoalPaceStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'COMPLETED':
        return GoalPaceStatus.completed;
      case 'AHEAD':
        return GoalPaceStatus.ahead;
      case 'ON_TRACK':
        return GoalPaceStatus.onTrack;
      case 'BEHIND':
        return GoalPaceStatus.behind;
      case 'OVERDUE':
        return GoalPaceStatus.overdue;
      default:
        return GoalPaceStatus.onTrack;
    }
  }

  String get label {
    switch (this) {
      case GoalPaceStatus.completed:
        return 'Achieved';
      case GoalPaceStatus.ahead:
        return 'Ahead of Schedule';
      case GoalPaceStatus.onTrack:
        return 'On Track';
      case GoalPaceStatus.behind:
        return 'Behind Pace';
      case GoalPaceStatus.overdue:
        return 'Target Date Passed';
    }
  }

  Color get color {
    switch (this) {
      case GoalPaceStatus.completed:
        return const Color(0xFF10B981);
      case GoalPaceStatus.ahead:
        return const Color(0xFF06B6D4);
      case GoalPaceStatus.onTrack:
        return const Color(0xFF10B981);
      case GoalPaceStatus.behind:
        return const Color(0xFFF59E0B);
      case GoalPaceStatus.overdue:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case GoalPaceStatus.completed:
        return Icons.check_circle_rounded;
      case GoalPaceStatus.ahead:
        return Icons.trending_up_rounded;
      case GoalPaceStatus.onTrack:
        return Icons.done_all_rounded;
      case GoalPaceStatus.behind:
        return Icons.warning_amber_rounded;
      case GoalPaceStatus.overdue:
        return Icons.error_outline_rounded;
    }
  }
}

class GoalEntity {
  final String id;
  final String userId;
  final String? linkedAccountId;
  final String? linkedAccountName;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double remainingAmount;
  final double progressPercentage;
  final DateTime targetDate;
  final int daysRemaining;
  final GoalPaceStatus paceStatus;
  final double expectedPaceAmount;
  final double paceDifference;
  final double requiredMonthlySavings;
  final double requiredWeeklySavings;
  final double requiredDailySavings;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalEntity({
    required this.id,
    required this.userId,
    this.linkedAccountId,
    this.linkedAccountName,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.remainingAmount,
    required this.progressPercentage,
    required this.targetDate,
    required this.daysRemaining,
    required this.paceStatus,
    required this.expectedPaceAmount,
    required this.paceDifference,
    required this.requiredMonthlySavings,
    required this.requiredWeeklySavings,
    required this.requiredDailySavings,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalEntity.fromJson(Map<String, dynamic> json) {
    return GoalEntity(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      linkedAccountId: json['linkedAccountId'] as String?,
      linkedAccountName: json['linkedAccountName'] as String?,
      name: json['name'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
      paceStatus: GoalPaceStatus.fromString(json['paceStatus'] as String? ?? 'ON_TRACK'),
      expectedPaceAmount: (json['expectedPaceAmount'] as num?)?.toDouble() ?? 0.0,
      paceDifference: (json['paceDifference'] as num?)?.toDouble() ?? 0.0,
      requiredMonthlySavings: (json['requiredMonthlySavings'] as num?)?.toDouble() ?? 0.0,
      requiredWeeklySavings: (json['requiredWeeklySavings'] as num?)?.toDouble() ?? 0.0,
      requiredDailySavings: (json['requiredDailySavings'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class GoalsSummary {
  final double totalTargetAmount;
  final double totalCurrentAmount;
  final double totalRemainingAmount;
  final double overallProgressPercentage;
  final int activeGoalsCount;
  final int completedGoalsCount;

  const GoalsSummary({
    required this.totalTargetAmount,
    required this.totalCurrentAmount,
    required this.totalRemainingAmount,
    required this.overallProgressPercentage,
    required this.activeGoalsCount,
    required this.completedGoalsCount,
  });

  factory GoalsSummary.fromJson(Map<String, dynamic> json) {
    return GoalsSummary(
      totalTargetAmount: (json['totalTargetAmount'] as num?)?.toDouble() ?? 0.0,
      totalCurrentAmount: (json['totalCurrentAmount'] as num?)?.toDouble() ?? 0.0,
      totalRemainingAmount: (json['totalRemainingAmount'] as num?)?.toDouble() ?? 0.0,
      overallProgressPercentage: (json['overallProgressPercentage'] as num?)?.toDouble() ?? 0.0,
      activeGoalsCount: (json['activeGoalsCount'] as num?)?.toInt() ?? 0,
      completedGoalsCount: (json['completedGoalsCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory GoalsSummary.empty() {
    return const GoalsSummary(
      totalTargetAmount: 0,
      totalCurrentAmount: 0,
      totalRemainingAmount: 0,
      overallProgressPercentage: 0,
      activeGoalsCount: 0,
      completedGoalsCount: 0,
    );
  }
}
