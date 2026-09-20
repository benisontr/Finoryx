import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../accounts/presentation/accounts_controller.dart';
import '../../transactions/presentation/transactions_controller.dart';
import '../../transactions/presentation/quick_add_transaction_sheet.dart';
import '../../transactions/domain/transaction_entity.dart';
import '../domain/dashboard_analytics_entity.dart';
import 'dashboard_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/finoryx_card.dart';
import '../../../core/widgets/finoryx_pill.dart';
import '../../../core/widgets/finoryx_section_header.dart';
import '../../../core/widgets/finoryx_ai_insight_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final transactionsState = ref.watch(transactionsNotifierProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = ref.watch(userCurrencySymbolProvider);

    final analytics = dashboardState.analytics;
    final netWorth = analytics?.netWorth;
    final cashFlow = analytics?.cashFlow;
    final recentTransactions = transactionsState.transactions.take(4).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        leadingWidth: 52,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'B',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${_getGreeting()}, ${user?.fullName ?? 'Benison T R'}',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('👋', style: TextStyle(fontSize: 14)),
              ],
            ),
            Text(
              'Your financial overview',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab',
        onPressed: () => QuickAddTransactionSheet.show(context),
        backgroundColor: AppColors.primary,
        elevation: 3,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.read(dashboardControllerProvider.notifier).loadDashboard(),
          ref.read(accountsNotifierProvider.notifier).loadAccounts(),
          ref.read(transactionsNotifierProvider.notifier).loadTransactions(),
        ]),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Compact Net Worth Hero Card
              _buildNetWorthHeroCard(
                context,
                ref,
                netWorth: netWorth,
                isDark: isDark,
                currencySymbol: currencySymbol,
                isHidden: dashboardState.isBalanceHidden,
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. FINORYX AI Copilot Insight Card
              _buildAiInsightSection(context, cashFlow, analytics),
              const SizedBox(height: AppSpacing.md),

              // 4. Monthly Cash Flow Summary Card
              if (cashFlow != null)
                _buildCashFlowCard(cashFlow, isDark, currencySymbol),
              const SizedBox(height: AppSpacing.md),

              // 5. Category Spending Breakdown
              if (analytics != null && analytics.spendingBreakdown.isNotEmpty) ...[
                _buildSpendingBreakdownCard(
                  context,
                  analytics.spendingBreakdown,
                  cashFlow?.totalExpense ?? 0,
                  isDark,
                  currencySymbol,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 6. Budgets & Goals Highlights
              if (analytics != null) ...[
                _buildBudgetsAndGoalsRow(context, analytics, isDark, currencySymbol),
                const SizedBox(height: AppSpacing.md),
              ],

              // 7. Recent Transactions List
              _buildRecentTransactionsSection(
                context,
                recentTransactions,
                isDark,
                currencySymbol,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetWorthHeroCard(
    BuildContext context,
    WidgetRef ref, {
    required DashboardNetWorth? netWorth,
    required bool isDark,
    required String currencySymbol,
    required bool isHidden,
  }) {
    final totalNet = netWorth?.netWorth ?? 0.0;
    final assets = netWorth?.totalAssets ?? 0.0;
    final liabilities = netWorth?.totalLiabilities ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF5B5CE2), Color(0xFF7C5CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B5CE2).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'TOTAL NET WORTH',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(dashboardControllerProvider.notifier).toggleBalanceVisibility(),
                      child: Icon(
                        isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white70,
                        size: 17,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${netWorth?.accountsCount ?? 0} Accounts',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isHidden
                  ? '••••••••'
                  : '$currencySymbol${NumberFormat('#,##0.00').format(totalNet)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Assets', style: TextStyle(color: Colors.white60, fontSize: 10)),
                            Text(
                              isHidden ? '••••••' : '$currencySymbol${NumberFormat('#,##0.00').format(assets)}',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(height: 20, width: 1, color: Colors.white24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFFF87171), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Liabilities', style: TextStyle(color: Colors.white60, fontSize: 10)),
                            Text(
                              isHidden ? '••••••' : '$currencySymbol${NumberFormat('#,##0.00').format(liabilities)}',
                              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAiInsightSection(
    BuildContext context,
    DashboardCashFlow? cashFlow,
    DashboardAnalyticsEntity? analytics,
  ) {
    String insightText;
    if (cashFlow != null && cashFlow.savingsRate >= 25) {
      insightText = "Your savings rate is strong at ${cashFlow.savingsRate.toStringAsFixed(1)}% this month. You're maintaining a healthy surplus.";
    } else if (analytics != null && analytics.budgetsSummary.warningCount > 0) {
      insightText = "${analytics.budgetsSummary.warningCount} category budget is pacing faster than normal this month. Tap below to review your pace.";
    } else {
      insightText = "Your spending is currently on track with your projected financial goals.";
    }

    return FinoryxAiInsightCard(
      message: insightText,
      onAction: () => context.push('/assistant'),
    );
  }

  Widget _buildCashFlowCard(
    DashboardCashFlow cashFlow,
    bool isDark,
    String currencySymbol,
  ) {
    return FinoryxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MONTHLY CASH FLOW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              FinoryxPill(
                label: 'Savings Rate: ${cashFlow.savingsRate.toStringAsFixed(1)}%',
                variant: FinoryxPillVariant.income,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.incomeContainer,
                      child: Icon(Icons.arrow_downward_rounded, color: AppColors.income, size: 15),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Income', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        Text(
                          '$currencySymbol${NumberFormat('#,##0.00').format(cashFlow.totalIncome)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.income),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.expenseContainer,
                      child: Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 15),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expenses', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        Text(
                          '$currencySymbol${NumberFormat('#,##0.00').format(cashFlow.totalExpense)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.expense),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Cash Flow',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  '${cashFlow.netCashFlow >= 0 ? '+' : ''}$currencySymbol${NumberFormat('#,##0.00').format(cashFlow.netCashFlow)}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: cashFlow.netCashFlow >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingBreakdownCard(
    BuildContext context,
    List<CategorySpendingItem> categories,
    double totalExpense,
    bool isDark,
    String currencySymbol,
  ) {
    return FinoryxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinoryxSectionHeader(
            title: 'Top Spending Breakdown',
            actionLabel: 'Reports →',
            onAction: () => context.push('/reports'),
          ),
          ...categories.take(3).map((cat) {
            Color catColor = Color(int.tryParse(cat.categoryColorHex.replaceFirst('#', '0xFF')) ?? 0xFF5B5CE2);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat.categoryName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$currencySymbol${NumberFormat('#,##0.00').format(cat.amount)} (${cat.percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
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
                      value: (cat.percentage / 100).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBudgetsAndGoalsRow(
    BuildContext context,
    DashboardAnalyticsEntity analytics,
    bool isDark,
    String currencySymbol,
  ) {
    final bSummary = analytics.budgetsSummary;
    final gSummary = analytics.goalsSummary;

    return Row(
      children: [
        // Budgets Mini Card
        Expanded(
          child: FinoryxCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            onTap: () => context.push('/budgets'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BUDGETS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${bSummary.overallPercentage.toStringAsFixed(0)}% Spent',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: (bSummary.overallPercentage / 100).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(bSummary.overallPercentage > 100 ? AppColors.expense : AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Goals Mini Card
        Expanded(
          child: FinoryxCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            onTap: () => context.push('/goals'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GOALS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${gSummary.overallProgress.toStringAsFixed(0)}% Saved',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: (gSummary.overallProgress / 100).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(
    BuildContext context,
    List<TransactionEntity> transactions,
    bool isDark,
    String currencySymbol,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinoryxSectionHeader(
          title: 'Recent Transactions',
          actionLabel: 'View All',
          onAction: () => context.push('/transactions'),
        ),
        if (transactions.isEmpty)
          FinoryxCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text(
                'No transactions recorded yet.',
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          )
        else
          FinoryxCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (ctx, idx) => Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              itemBuilder: (ctx, index) {
                final tx = transactions[index];
                final isIncome = tx.type == TransactionType.income;
                final isTransfer = tx.type == TransactionType.transfer;

                Color iconColor = isIncome ? AppColors.income : (isTransfer ? AppColors.info : AppColors.expense);
                Color iconBg = isIncome ? AppColors.incomeContainer : (isTransfer ? AppColors.infoContainer : AppColors.expenseContainer);
                IconData iconData = isIncome ? Icons.arrow_downward_rounded : (isTransfer ? Icons.sync_alt_rounded : Icons.arrow_upward_rounded);

                final desc = (tx.description != null && tx.description!.isNotEmpty)
                    ? tx.description!
                    : (tx.categoryName ?? 'Transaction');

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 17,
                    backgroundColor: iconBg,
                    child: Icon(iconData, color: iconColor, size: 16),
                  ),
                  title: Text(
                    desc,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(tx.transactionDate),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  trailing: Text(
                    '${isIncome ? '+' : (isTransfer ? '' : '-')}$currencySymbol${NumberFormat('#,##0.00').format(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isIncome
                          ? AppColors.income
                          : (isTransfer ? AppColors.info : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
