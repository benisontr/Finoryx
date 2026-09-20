import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../dashboard/domain/dashboard_analytics_entity.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/finoryx_card.dart';
import '../../../core/widgets/finoryx_pill.dart';
import '../../../core/widgets/finoryx_button.dart';
import '../../../core/widgets/finoryx_section_header.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedPeriodMonths = 1; // Default to 'This Month'

  void _showExportOptions(DashboardAnalyticsEntity analytics, String currencySymbol) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Material(
        color: Theme.of(ctx).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Export Statement Format',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose file format to download or view your statement',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.table_chart_outlined, color: Color(0xFF16A34A)),
                  ),
                  title: const Text('Export as CSV (.csv)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Direct download tabular spreadsheet to device'),
                  trailing: const Icon(Icons.download_rounded),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _exportCsv(analytics, currencySymbol);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFDC2626)),
                  ),
                  title: const Text('Export as PDF (.pdf)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Save or print formatted executive PDF statement'),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _exportPdf(analytics, currencySymbol);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _exportCsv(DashboardAnalyticsEntity analytics, String currencySymbol) {
    final now = DateTime.now();
    final filename = 'Finoryx_Financial_Report_${DateFormat('yyyyMMdd_HHmm').format(now)}.csv';
    final allTrends = analytics.cashFlowTrends;
    final startIndex = (allTrends.length - _selectedPeriodMonths).clamp(0, allTrends.length);
    final trends = allTrends.sublist(startIndex);

    final buffer = StringBuffer();
    buffer.writeln('FINORYX FINANCIAL REPORT');
    buffer.writeln('Generated on,${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}');
    buffer.writeln('Period,${_selectedPeriodMonths == 1 ? "This Month" : "Past $_selectedPeriodMonths Months"}');
    buffer.writeln('Currency,$currencySymbol');
    buffer.writeln('');

    buffer.writeln('=== EXECUTIVE CASH FLOW SUMMARY ===');
    buffer.writeln('Month,Income ($currencySymbol),Expense ($currencySymbol),Net Cash Flow ($currencySymbol)');
    for (final t in trends) {
      buffer.writeln('${t.label} ${t.year},${t.income.toStringAsFixed(2)},${t.expense.toStringAsFixed(2)},${t.netCashFlow.toStringAsFixed(2)}');
    }
    buffer.writeln('');

    buffer.writeln('=== CURRENT NET WORTH ===');
    buffer.writeln('Total Assets,$currencySymbol${analytics.netWorth.totalAssets.toStringAsFixed(2)}');
    buffer.writeln('Total Liabilities,$currencySymbol${analytics.netWorth.totalLiabilities.toStringAsFixed(2)}');
    buffer.writeln('Net Worth,$currencySymbol${analytics.netWorth.netWorth.toStringAsFixed(2)}');
    buffer.writeln('');

    buffer.writeln('=== EXPENSE BREAKDOWN BY CATEGORY ===');
    buffer.writeln('Category,Amount ($currencySymbol),Percentage (%)');
    for (final cat in analytics.spendingBreakdown) {
      buffer.writeln('"${cat.categoryName}",${cat.amount.toStringAsFixed(2)},${cat.percentage.toStringAsFixed(1)}%');
    }

    AppFormatters.saveFile(
      filename: filename,
      bytes: utf8.encode(buffer.toString()),
      mimeType: 'text/csv;charset=utf-8',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$filename downloaded to your Downloads location!'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  void _exportPdf(DashboardAnalyticsEntity analytics, String currencySymbol) {
    final now = DateTime.now();
    final allTrends = analytics.cashFlowTrends;
    final startIndex = (allTrends.length - _selectedPeriodMonths).clamp(0, allTrends.length);
    final trends = allTrends.sublist(startIndex);

    double periodIncome = 0;
    double periodExpense = 0;
    for (final t in trends) {
      periodIncome += t.income;
      periodExpense += t.expense;
    }
    final netSaved = periodIncome - periodExpense;
    final savingsRate = periodIncome > 0 ? (netSaved / periodIncome) * 100 : 0.0;
    final periodLabel = _selectedPeriodMonths == 1 ? "This Month" : "Past $_selectedPeriodMonths Months";

    final htmlContent = '''
      <div class="header">
        <div>
          <div class="brand">Finoryx</div>
          <div class="date">AI Personal Finance OS &bull; Executive Statement</div>
        </div>
        <div style="text-align: right;">
          <div style="font-weight: 700; font-size: 14px;">${DateFormat('MMMM dd, yyyy').format(now)}</div>
          <div class="date">Period: $periodLabel</div>
        </div>
      </div>

      <div class="card">
        <div class="title">Executive Accumulation</div>
        <div class="amount-hero">$currencySymbol${NumberFormat('#,##0.00').format(netSaved)}</div>
        <div class="stat-grid">
          <div>
            <div class="stat-label">Total Inflow (Income)</div>
            <div class="stat-val" style="color: #059669;">+$currencySymbol${NumberFormat('#,##0.00').format(periodIncome)}</div>
          </div>
          <div>
            <div class="stat-label">Total Outflow (Expenses)</div>
            <div class="stat-val" style="color: #dc2626;">-$currencySymbol${NumberFormat('#,##0.00').format(periodExpense)}</div>
          </div>
          <div>
            <div class="stat-label">Savings Rate</div>
            <div class="stat-val"><span class="badge">${savingsRate.toStringAsFixed(1)}% Optimal</span></div>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="title">Net Worth Overview</div>
        <div class="stat-grid">
          <div>
            <div class="stat-label">Total Assets</div>
            <div class="stat-val">$currencySymbol${NumberFormat('#,##0.00').format(analytics.netWorth.totalAssets)}</div>
          </div>
          <div>
            <div class="stat-label">Total Liabilities</div>
            <div class="stat-val" style="color: #dc2626;">$currencySymbol${NumberFormat('#,##0.00').format(analytics.netWorth.totalLiabilities)}</div>
          </div>
          <div>
            <div class="stat-label">Total Net Worth</div>
            <div class="stat-val" style="color: #0f766e;">$currencySymbol${NumberFormat('#,##0.00').format(analytics.netWorth.netWorth)}</div>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="title">Monthly Cash Flow Trends</div>
        <table>
          <thead>
            <tr>
              <th>Month & Year</th>
              <th>Income</th>
              <th>Expense</th>
              <th>Net Cash Flow</th>
            </tr>
          </thead>
          <tbody>
            ${trends.map((t) => '''
              <tr>
                <td style="font-weight: 600;">${t.label} ${t.year}</td>
                <td style="color: #059669; font-weight: 600;">+$currencySymbol${NumberFormat('#,##0.00').format(t.income)}</td>
                <td style="color: #dc2626; font-weight: 600;">-$currencySymbol${NumberFormat('#,##0.00').format(t.expense)}</td>
                <td style="font-weight: 700; color: ${t.netCashFlow >= 0 ? '#059669' : '#dc2626'};">$currencySymbol${NumberFormat('#,##0.00').format(t.netCashFlow)}</td>
              </tr>
            ''').join('')}
          </tbody>
        </table>
      </div>

      ${analytics.spendingBreakdown.isNotEmpty ? '''
      <div class="card">
        <div class="title">Expense Breakdown by Category</div>
        <table>
          <thead>
            <tr>
              <th>Category</th>
              <th>Amount</th>
              <th>Distribution (%)</th>
            </tr>
          </thead>
          <tbody>
            ${analytics.spendingBreakdown.map((cat) => '''
              <tr>
                <td style="font-weight: 600;">${cat.categoryName}</td>
                <td>$currencySymbol${NumberFormat('#,##0.00').format(cat.amount)}</td>
                <td><span style="font-weight: 700; color: #065f46;">${cat.percentage.toStringAsFixed(1)}%</span></td>
              </tr>
            ''').join('')}
          </tbody>
        </table>
      </div>
      ''' : ''}
    ''';

    AppFormatters.openPrintableHtml(
      title: 'Finoryx Financial Statement - ${DateFormat('yyyy-MM-dd').format(now)}',
      htmlContent: htmlContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = ref.watch(userCurrencySymbolProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final analytics = dashboardState.analytics;

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
          'Financial Analytics & Reports',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (analytics != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Export Statement',
              onPressed: () => _showExportOptions(analytics, currencySymbol),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardControllerProvider.notifier).loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Selector Chips in logical order: This Month, Past 3 Months, Past 6 Months
              Row(
                children: [
                  _buildPeriodChip(1, 'This Month', isDark),
                  const SizedBox(width: 8),
                  _buildPeriodChip(3, 'Past 3 Months', isDark),
                  const SizedBox(width: 8),
                  _buildPeriodChip(6, 'Past 6 Months', isDark),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (dashboardState.isLoading && analytics == null)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
              else if (analytics != null) ...[
                // 1. Executive Summary Hero Card
                _buildExecutiveSummaryCard(analytics, isDark, currencySymbol),
                const SizedBox(height: AppSpacing.md),

                // 2. Multi-Month Cash Flow Trends Chart
                _buildCashFlowTrendsChart(analytics.cashFlowTrends, isDark, currencySymbol),
                const SizedBox(height: AppSpacing.md),

                // 3. Financial Health Scorecard
                _buildHealthScorecard(analytics, isDark),
                const SizedBox(height: AppSpacing.md),

                // 4. Category Spending Distribution
                if (analytics.spendingBreakdown.isNotEmpty) ...[
                  _buildCategoryDistributionCard(analytics.spendingBreakdown, isDark, currencySymbol),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 5. Export Button
                FinoryxButton(
                  text: 'Export Statement (PDF / CSV)',
                  icon: Icons.picture_as_pdf_outlined,
                  variant: FinoryxButtonVariant.primary,
                  onPressed: () => _showExportOptions(analytics, currencySymbol),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(int months, String label, bool isDark) {
    final isSelected = _selectedPeriodMonths == months;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedPeriodMonths = months);
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

  Widget _buildExecutiveSummaryCard(
    DashboardAnalyticsEntity analytics,
    bool isDark,
    String currencySymbol,
  ) {
    final allTrends = analytics.cashFlowTrends;
    final startIndex = (allTrends.length - _selectedPeriodMonths).clamp(0, allTrends.length);
    final trends = allTrends.sublist(startIndex);

    double totalPeriodIncome = 0;
    double totalPeriodExpense = 0;

    for (final t in trends) {
      totalPeriodIncome += t.income;
      totalPeriodExpense += t.expense;
    }

    final netSaved = totalPeriodIncome - totalPeriodExpense;
    final avgSavingsRate = totalPeriodIncome > 0 ? (netSaved / totalPeriodIncome) * 100 : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
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
                'EXECUTIVE SUMMARY',
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
                  'Savings Rate: ${avgSavingsRate.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppFormatters.currency(netSaved, symbol: currencySymbol),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Text('Net Capital Accumulation', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Inflow', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.currency(totalPeriodIncome, symbol: currencySymbol),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                Container(height: 20, width: 1, color: Colors.white24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Outflow', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.currency(totalPeriodExpense, symbol: currencySymbol),
                        style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowTrendsChart(
    List<CashFlowTrendPoint> trends,
    bool isDark,
    String currencySymbol,
  ) {
    final startIndex = (trends.length - _selectedPeriodMonths).clamp(0, trends.length);
    final filtered = trends.sublist(startIndex);

    double maxAmount = 100;
    for (final t in filtered) {
      if (t.income > maxAmount) maxAmount = t.income;
      if (t.expense > maxAmount) maxAmount = t.expense;
    }

    return FinoryxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CASH FLOW TRENDS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              Row(
                children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.income, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Inflow', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  const SizedBox(width: 8),
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.expense, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Outflow', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: filtered.map((point) {
                final incomeHeight = ((point.income / maxAmount) * 90).clamp(4.0, 90.0);
                final expenseHeight = ((point.expense / maxAmount) * 90).clamp(4.0, 90.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 12,
                          height: incomeHeight,
                          decoration: BoxDecoration(
                            color: AppColors.income,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Container(
                          width: 12,
                          height: expenseHeight,
                          decoration: BoxDecoration(
                            color: AppColors.expense,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      point.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScorecard(
    DashboardAnalyticsEntity analytics,
    bool isDark,
  ) {
    final savingsRate = analytics.cashFlow.savingsRate;
    final isSavingsHealthy = savingsRate >= 20;
    final isBudgetHealthy = analytics.budgetsSummary.exceededCount == 0;
    final isDebtHealthy = analytics.netWorth.totalLiabilities < analytics.netWorth.totalAssets * 0.4;

    return FinoryxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinoryxSectionHeader(title: 'Financial Health Scorecard'),
          _buildHealthRow(
            title: 'Savings Discipline',
            subtitle: '${savingsRate.toStringAsFixed(1)}% savings rate recorded',
            isGood: isSavingsHealthy,
            isDark: isDark,
          ),
          const Divider(height: 14),
          _buildHealthRow(
            title: 'Budget Compliance',
            subtitle: analytics.budgetsSummary.exceededCount == 0
                ? 'All spending categories within limits'
                : '${analytics.budgetsSummary.exceededCount} category budget(s) exceeded',
            isGood: isBudgetHealthy,
            isDark: isDark,
          ),
          const Divider(height: 14),
          _buildHealthRow(
            title: 'Leverage & Liability Health',
            subtitle: isDebtHealthy ? 'Low debt exposure relative to assets' : 'Moderate debt leverage',
            isGood: isDebtHealthy,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow({
    required String title,
    required String subtitle,
    required bool isGood,
    required bool isDark,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: (isGood ? AppColors.incomeContainer : AppColors.warningContainer),
          child: Icon(
            isGood ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
            size: 16,
            color: isGood ? const Color(0xFF065F46) : const Color(0xFF92400E),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        FinoryxPill(
          label: isGood ? 'OPTIMAL' : 'MONITOR',
          variant: isGood ? FinoryxPillVariant.income : FinoryxPillVariant.warning,
        ),
      ],
    );
  }

  Widget _buildCategoryDistributionCard(
    List<CategorySpendingItem> breakdown,
    bool isDark,
    String currencySymbol,
  ) {
    return FinoryxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinoryxSectionHeader(title: 'Expense Breakdown by Category'),
          ...breakdown.map((item) {
            Color catColor = Color(int.tryParse(item.categoryColorHex.replaceFirst('#', '0xFF')) ?? 0xFF5B5CE2);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.categoryName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${AppFormatters.currency(item.amount, symbol: currencySymbol)} (${item.percentage.toStringAsFixed(1)}%)',
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
                      value: (item.percentage / 100).clamp(0.0, 1.0),
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
}
