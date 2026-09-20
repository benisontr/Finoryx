import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/budget_entity.dart';
import 'budgets_controller.dart';
import 'create_budget_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/finoryx_card.dart';
import '../../../core/widgets/finoryx_pill.dart';
import '../../../core/widgets/finoryx_empty_state.dart';
import '../../../core/widgets/finoryx_section_header.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  void _showCreateBudgetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreateBudgetSheet(),
    );
  }

  Future<void> _confirmDelete(BudgetEntity budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete the budget for ${budget.categoryName ?? 'this category'}?'),
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
      final success = await ref.read(budgetsNotifierProvider.notifier).deleteBudget(budget.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = ref.watch(userCurrencySymbolProvider);
    final state = ref.watch(budgetsNotifierProvider);

    final totalLimit = state.budgets.fold<double>(0, (sum, b) => sum + b.limitAmount);
    final totalSpent = state.budgets.fold<double>(0, (sum, b) => sum + b.spentAmount);
    final totalRemaining = totalLimit - totalSpent;
    final overallPercentage = totalLimit > 0 ? (totalSpent / totalLimit) * 100 : 0.0;

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
          'Category Budgets',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(budgetsNotifierProvider.notifier).loadBudgets(),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'budgets_fab',
        onPressed: _showCreateBudgetSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Set Budget', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(budgetsNotifierProvider.notifier).loadBudgets(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Monthly Budget Overview Card
              if (state.budgets.isNotEmpty)
                _buildMonthlySummaryCard(
                  totalLimit: totalLimit,
                  totalSpent: totalSpent,
                  totalRemaining: totalRemaining,
                  overallPercentage: overallPercentage,
                  isDark: isDark,
                  currencySymbol: currencySymbol,
                ),
              const SizedBox(height: AppSpacing.md),

              if (state.isLoading && state.budgets.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
              else if (state.budgets.isEmpty)
                FinoryxEmptyState(
                  icon: Icons.pie_chart_outline,
                  title: 'No Budgets Configured',
                  subtitle: 'Set monthly limits on your spending categories to activate the burn-rate pace engine.',
                  actionLabel: 'Create First Budget',
                  onAction: _showCreateBudgetSheet,
                )
              else ...[
                const FinoryxSectionHeader(title: 'Active Category Budgets'),
                ...state.budgets.map((b) => _buildBudgetCard(context, b, isDark, currencySymbol)),
                const SizedBox(height: 80),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCard({
    required double totalLimit,
    required double totalSpent,
    required double totalRemaining,
    required double overallPercentage,
    required bool isDark,
    required String currencySymbol,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
              : [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
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
                'TOTAL MONTHLY BUDGET',
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
                  '${overallPercentage.toStringAsFixed(1)}% Used',
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
                AppFormatters.currency(totalSpent, symbol: currencySymbol),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'of ${AppFormatters.currency(totalLimit, symbol: currencySymbol)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: (overallPercentage / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                overallPercentage > 100 ? const Color(0xFFF87171) : const Color(0xFF38BDF8),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining Buffer: ${AppFormatters.currency(totalRemaining > 0 ? totalRemaining : 0, symbol: currencySymbol)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                DateFormat('MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    BudgetEntity budget,
    bool isDark,
    String currencySymbol,
  ) {
    Color catColor = Color(int.tryParse((budget.categoryColorHex ?? '#5B5CE2').replaceFirst('#', '0xFF')) ?? 0xFF5B5CE2);

    FinoryxPillVariant pillVariant;
    if (budget.burnRateStatus == BurnRateStatus.exceeded) {
      pillVariant = FinoryxPillVariant.expense;
    } else if (budget.burnRateStatus == BurnRateStatus.warning) {
      pillVariant = FinoryxPillVariant.warning;
    } else {
      pillVariant = FinoryxPillVariant.income;
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
                  backgroundColor: catColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  child: Icon(Icons.pie_chart_outline, color: catColor, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.categoryName ?? 'Category',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Limit: ${AppFormatters.currency(budget.limitAmount, symbol: currencySymbol)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FinoryxPill(
                  label: budget.burnRateStatus.label,
                  variant: pillVariant,
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  onSelected: (val) {
                    if (val == 'delete') _confirmDelete(budget);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: AppColors.expense),
                          SizedBox(width: 8),
                          Text('Delete Budget', style: TextStyle(color: AppColors.expense)),
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
                  '${AppFormatters.currency(budget.spentAmount, symbol: currencySymbol)} spent',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  '${budget.spentPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: budget.burnRateStatus == BurnRateStatus.exceeded ? AppColors.expense : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: (budget.spentPercentage / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(
                  budget.burnRateStatus == BurnRateStatus.exceeded
                      ? AppColors.expense
                      : (budget.burnRateStatus == BurnRateStatus.warning ? AppColors.warning : AppColors.income),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining: ${AppFormatters.currency(budget.remainingAmount, symbol: currencySymbol)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  'Projected: ${AppFormatters.currency(budget.projectedSpend, symbol: currencySymbol)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
