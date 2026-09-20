import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { SupabaseService } from '../../database/supabase.service';
import { BudgetsService } from '../budgets/budgets.service';
import { GoalsService } from '../goals/goals.service';
import {
  DashboardSummaryEntity,
  CategorySpendingItem,
  CashFlowTrendPoint,
} from './entities/dashboard-summary.entity';
import { BurnRateStatus } from '../budgets/entities/budget.entity';

@Injectable()
export class AnalyticsService {
  private readonly logger = new Logger(AnalyticsService.name);

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly budgetsService: BudgetsService,
    private readonly goalsService: GoalsService,
  ) {}

  async getDashboardSummary(
    userId: string,
    targetMonth?: number,
    targetYear?: number,
  ): Promise<DashboardSummaryEntity> {
    const supabase = this.supabaseService.getAdminClient();
    const now = new Date();
    const month = targetMonth || now.getMonth() + 1;
    const year = targetYear || now.getFullYear();

    try {
      // Date bounds
      const startDateStr = new Date(Date.UTC(year, month - 1, 1)).toISOString().split('T')[0];
      const endDateStr = new Date(Date.UTC(year, month, 0)).toISOString().split('T')[0];
      const sixMonthsAgoStartDate = new Date(Date.UTC(year, month - 6, 1));
      const sixMonthsAgoStartStr = sixMonthsAgoStartDate.toISOString().split('T')[0];

      // Execute all database queries concurrently in a single round-trip batch
      const [accountsRes, transactionsRes, budgets, goalsRes] = await Promise.all([
        supabase
          .from('accounts')
          .select('*')
          .eq('user_id', userId),
        supabase
          .from('transactions')
          .select('*, categories:category_id ( id, name, icon, color_hex )')
          .eq('user_id', userId)
          .gte('transaction_date', sixMonthsAgoStartStr)
          .lte('transaction_date', endDateStr),
        this.budgetsService.getBudgets(userId, month, year),
        this.goalsService.findAll(userId),
      ]);

      if (accountsRes.error) {
        throw new BadRequestException(`Failed to fetch accounts: ${accountsRes.error.message}`);
      }
      if (transactionsRes.error) {
        throw new BadRequestException(`Failed to fetch transactions: ${transactionsRes.error.message}`);
      }

      const accounts = accountsRes.data || [];
      const allTransactions = transactionsRes.data || [];

      // 1. Calculate Net Worth
      const liabilityTypes = ['CREDIT_CARD', 'LOAN', 'MORTGAGE', 'OTHER_LIABILITY'];
      let totalAssets = 0;
      let totalLiabilities = 0;

      for (const acc of accounts) {
        const balance = parseFloat(acc.current_balance) || 0.0;
        const type = (acc.account_type || acc.type || '').toUpperCase();
        if (liabilityTypes.includes(type)) {
          totalLiabilities += Math.abs(balance);
        } else {
          totalAssets += balance;
        }
      }

      const netWorth = totalAssets - totalLiabilities;

      // 2. Filter target month transactions and compute cash flow & category breakdown
      let totalIncome = 0;
      let totalExpense = 0;
      const categorySpendMap = new Map<
        string,
        { name: string; icon: string; colorHex: string; amount: number }
      >();

      const monthTransactions = allTransactions.filter(
        (tx) => tx.transaction_date >= startDateStr && tx.transaction_date <= endDateStr,
      );

      for (const tx of monthTransactions) {
        const amount = parseFloat(tx.amount) || 0.0;
        const type = (tx.type || '').toUpperCase();

        if (type === 'INCOME') {
          totalIncome += amount;
        } else if (type === 'EXPENSE') {
          totalExpense += amount;
          const catId = tx.category_id || 'uncategorized';
          const catName = tx.categories?.name || 'Uncategorized';
          const catIcon = tx.categories?.icon || 'help_outline';
          const catColor = tx.categories?.color_hex || '#94A3B8';

          const current = categorySpendMap.get(catId) || {
            name: catName,
            icon: catIcon,
            colorHex: catColor,
            amount: 0,
          };
          current.amount += amount;
          categorySpendMap.set(catId, current);
        }
      }

      const netCashFlow = totalIncome - totalExpense;
      const savingsRate =
        totalIncome > 0 ? Math.max(0, ((totalIncome - totalExpense) / totalIncome) * 100) : 0;

      // Format Category Spending Breakdown
      const spendingBreakdown: CategorySpendingItem[] = Array.from(categorySpendMap.entries())
        .map(([catId, data]) => ({
          categoryId: catId,
          categoryName: data.name,
          categoryIcon: data.icon,
          categoryColorHex: data.colorHex,
          amount: Math.round(data.amount * 100) / 100,
          percentage:
            totalExpense > 0
              ? Math.round(((data.amount / totalExpense) * 100) * 10) / 10
              : 0,
        }))
        .sort((a, b) => b.amount - a.amount);

      // 3. Budgets Aggregation
      let totalBudgetLimit = 0;
      let totalBudgetSpent = 0;
      let warningCount = 0;
      let exceededCount = 0;

      for (const b of budgets) {
        totalBudgetLimit += b.limitAmount;
        totalBudgetSpent += b.spentAmount;
        if (b.burnRateStatus === BurnRateStatus.WARNING) warningCount++;
        if (b.burnRateStatus === BurnRateStatus.EXCEEDED) exceededCount++;
      }

      const overallBudgetPct =
        totalBudgetLimit > 0 ? (totalBudgetSpent / totalBudgetLimit) * 100 : 0;
      const criticalBudgets = budgets.filter(
        (b) =>
          b.burnRateStatus === BurnRateStatus.WARNING ||
          b.burnRateStatus === BurnRateStatus.EXCEEDED,
      );

      // 4. Goals Aggregation
      const activeGoals = goalsRes.goals.filter((g) => !g.isCompleted);
      const nearestGoal = activeGoals.length > 0 ? activeGoals[0] : undefined;

      // 5. Cash Flow Trends (Past 6 Months) aggregated in-memory
      const cashFlowTrends: CashFlowTrendPoint[] = [];
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      for (let i = 5; i >= 0; i--) {
        const trendDate = new Date(Date.UTC(year, month - 1 - i, 1));
        const tMonth = trendDate.getUTCMonth() + 1;
        const tYear = trendDate.getUTCFullYear();
        const tStart = new Date(Date.UTC(tYear, tMonth - 1, 1)).toISOString().split('T')[0];
        const tEnd = new Date(Date.UTC(tYear, tMonth, 0)).toISOString().split('T')[0];

        let tIncome = 0;
        let tExpense = 0;

        for (const tx of allTransactions) {
          if (tx.transaction_date >= tStart && tx.transaction_date <= tEnd) {
            const amt = parseFloat(tx.amount) || 0.0;
            const type = (tx.type || '').toUpperCase();
            if (type === 'INCOME') tIncome += amt;
            if (type === 'EXPENSE') tExpense += amt;
          }
        }

        cashFlowTrends.push({
          month: tMonth,
          year: tYear,
          label: `${monthNames[tMonth - 1]}`,
          income: Math.round(tIncome * 100) / 100,
          expense: Math.round(tExpense * 100) / 100,
          netCashFlow: Math.round((tIncome - tExpense) * 100) / 100,
        });
      }

      return {
        netWorth: {
          netWorth: Math.round(netWorth * 100) / 100,
          totalAssets: Math.round(totalAssets * 100) / 100,
          totalLiabilities: Math.round(totalLiabilities * 100) / 100,
          accountsCount: accounts.length,
        },
        cashFlow: {
          month,
          year,
          totalIncome: Math.round(totalIncome * 100) / 100,
          totalExpense: Math.round(totalExpense * 100) / 100,
          netCashFlow: Math.round(netCashFlow * 100) / 100,
          savingsRate: Math.round(savingsRate * 10) / 10,
        },
        spendingBreakdown,
        budgetsSummary: {
          totalBudgetLimit: Math.round(totalBudgetLimit * 100) / 100,
          totalBudgetSpent: Math.round(totalBudgetSpent * 100) / 100,
          overallPercentage: Math.round(overallBudgetPct * 10) / 10,
          warningCount,
          exceededCount,
          criticalBudgets,
        },
        goalsSummary: {
          totalTarget: goalsRes.summary.totalTargetAmount,
          totalSaved: goalsRes.summary.totalCurrentAmount,
          overallProgress: goalsRes.summary.overallProgressPercentage,
          activeCount: goalsRes.summary.activeGoalsCount,
          completedCount: goalsRes.summary.completedGoalsCount,
          nearestGoal,
        },
        cashFlowTrends,
      };
    } catch (err: any) {
      this.logger.error(`Error aggregating dashboard analytics: ${err.message}`);
      throw new BadRequestException(`Failed to load dashboard summary: ${err.message}`);
    }
  }
}
