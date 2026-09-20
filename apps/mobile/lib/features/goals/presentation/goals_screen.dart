import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/goal_entity.dart';
import 'goals_controller.dart';
import 'create_goal_sheet.dart';
import 'contribute_goal_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/finoryx_card.dart';
import '../../../core/widgets/finoryx_pill.dart';
import '../../../core/widgets/finoryx_empty_state.dart';
import '../../../core/widgets/finoryx_button.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: Achieved

  void _showCreateGoalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreateGoalSheet(),
    );
  }

  void _showContributeSheet(GoalEntity goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContributeGoalSheet(goal: goal),
    );
  }

  Future<void> _confirmDelete(GoalEntity goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(goalsControllerProvider.notifier).deleteGoal(goal.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = ref.watch(userCurrencySymbolProvider);
    final state = ref.watch(goalsControllerProvider);

    final filteredGoals = state.goals.where((g) {
      if (_selectedFilterIndex == 1) return !g.isCompleted;
      if (_selectedFilterIndex == 2) return g.isCompleted;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'Savings Goals',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(goalsControllerProvider.notifier).loadGoals(),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goals_fab',
        onPressed: _showCreateGoalSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(goalsControllerProvider.notifier).loadGoals(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Summary Card
              _buildSummaryHeroCard(state.summary, isDark, currencySymbol),
              const SizedBox(height: AppSpacing.md),

              // Filter Chips
              Row(
                children: [
                  _buildFilterChip(0, 'All (${state.goals.length})', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(1, 'Active (${state.summary.activeGoalsCount})', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, 'Achieved (${state.summary.completedGoalsCount})', isDark),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (state.isLoading && state.goals.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
              else if (filteredGoals.isEmpty)
                FinoryxEmptyState(
                  icon: Icons.savings_outlined,
                  title: _selectedFilterIndex == 0 ? 'No Savings Goals' : (_selectedFilterIndex == 1 ? 'No Active Goals' : 'No Achieved Goals'),
                  subtitle: 'Set specific savings milestones to activate the intelligent daily & monthly pace engine.',
                  actionLabel: 'Create New Goal',
                  onAction: _showCreateGoalSheet,
                )
              else ...[
                ...filteredGoals.map((g) => _buildGoalCard(context, g, isDark, currencySymbol)),
                const SizedBox(height: 80),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeroCard(GoalsSummary summary, bool isDark, String currencySymbol) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0C4A6E), const Color(0xFF0F172A)]
              : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL SAVINGS PROGRESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '${summary.overallProgressPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                AppFormatters.currency(summary.totalCurrentAmount, symbol: currencySymbol),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'of ${AppFormatters.currency(summary.totalTargetAmount, symbol: currencySymbol)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: (summary.overallProgressPercentage / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSummaryStat('Remaining', AppFormatters.currency(summary.totalRemainingAmount, symbol: currencySymbol)),
              const Spacer(),
              _buildSummaryStat('Active Goals', '${summary.activeGoalsCount}'),
              const Spacer(),
              _buildSummaryStat('Achieved', '${summary.completedGoalsCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
      ],
    );
  }

  Widget _buildFilterChip(int index, String label, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilterIndex = index);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    GoalEntity goal,
    bool isDark,
    String currencySymbol,
  ) {
    FinoryxPillVariant pillVariant;
    switch (goal.paceStatus) {
      case GoalPaceStatus.completed:
        pillVariant = FinoryxPillVariant.income;
        break;
      case GoalPaceStatus.ahead:
        pillVariant = FinoryxPillVariant.primary;
        break;
      case GoalPaceStatus.onTrack:
        pillVariant = FinoryxPillVariant.income;
        break;
      case GoalPaceStatus.behind:
        pillVariant = FinoryxPillVariant.warning;
        break;
      case GoalPaceStatus.overdue:
        pillVariant = FinoryxPillVariant.expense;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FinoryxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: goal.paceStatus.color.withValues(alpha: isDark ? 0.2 : 0.12),
                  child: Icon(goal.paceStatus.icon, color: goal.paceStatus.color, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: ${DateFormat('MMM dd, yyyy').format(goal.targetDate)} (${goal.daysRemaining}d left)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FinoryxPill(
                  label: goal.paceStatus.label,
                  variant: pillVariant,
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  onSelected: (val) {
                    if (val == 'delete') _confirmDelete(goal);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: AppColors.expense),
                          SizedBox(width: 8),
                          Text('Delete Goal', style: TextStyle(color: AppColors.expense)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppFormatters.currency(goal.currentAmount, symbol: currencySymbol)} saved',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  '${goal.progressPercentage.toStringAsFixed(1)}% of ${AppFormatters.currency(goal.targetAmount, symbol: currencySymbol)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: (goal.progressPercentage / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(goal.paceStatus.color),
              ),
            ),
            if (!goal.isCompleted) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Save ${AppFormatters.currency(goal.requiredMonthlySavings, symbol: currencySymbol)}/mo (${AppFormatters.currency(goal.requiredDailySavings, symbol: currencySymbol)}/day) to hit deadline.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FinoryxButton(
                text: 'Add Funds / Contribute',
                icon: Icons.add_card_rounded,
                variant: FinoryxButtonVariant.outline,
                height: 38,
                onPressed: () => _showContributeSheet(goal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
