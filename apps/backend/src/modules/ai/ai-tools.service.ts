import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../../database/supabase.service';
import { AnalyticsService } from '../analytics/analytics.service';
import { GoalsService } from '../goals/goals.service';
import { BudgetsService } from '../budgets/budgets.service';
import {
  AffordabilityStatus,
  AffordabilityInsightPayload,
  BurnRateInsightPayload,
  SavingsGoalInsightPayload,
  FinancialSummaryInsightPayload,
} from './entities/ai.entity';

@Injectable()
export class AiToolsService {
  private readonly logger = new Logger(AiToolsService.name);

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly analyticsService: AnalyticsService,
    private readonly goalsService: GoalsService,
    private readonly budgetsService: BudgetsService,
  ) {}

  /**
   * Tool: Retrieve grounded Net Worth, liquid cash, and balances
   */
  async getNetWorthAndBalances(userId: string): Promise<FinancialSummaryInsightPayload> {
    const supabase = this.supabaseService.getAdminClient();
    const { data: accounts, error } = await supabase
      .from('accounts')
      .select('*')
      .eq('user_id', userId);

    if (error) {
      this.logger.error(`Error fetching accounts for AI tool: ${error.message}`);
      return {
        netWorth: 0,
        totalAssets: 0,
        totalLiabilities: 0,
        liquidBuffer: 0,
        monthlySavingsRate: 0,
      };
    }

    const liabilityTypes = ['CREDIT_CARD', 'LOAN', 'MORTGAGE', 'OTHER_LIABILITY'];
    let totalAssets = 0;
    let totalLiabilities = 0;
    let liquidBuffer = 0;

    for (const acc of accounts || []) {
      const balance = parseFloat(acc.current_balance) || 0.0;
      const type = (acc.account_type || acc.type || '').toUpperCase();

      if (liabilityTypes.includes(type)) {
        totalLiabilities += Math.abs(balance);
      } else {
        totalAssets += balance;
        if (['BANK', 'CASH', 'DIGITAL_WALLET', 'SAVINGS'].includes(type) && balance > 0) {
          liquidBuffer += balance;
        }
      }
    }

    const netWorth = totalAssets - totalLiabilities;
    const analytics = await this.analyticsService.getDashboardSummary(userId);

    return {
      netWorth,
      totalAssets,
      totalLiabilities,
      liquidBuffer,
      monthlySavingsRate: analytics?.cashFlow?.savingsRate || 0,
    };
  }

  /**
   * Tool: Retrieve grounded Monthly Burn Rate & Category Spending
   */
  async getMonthlyBurnRate(
    userId: string,
    month?: number,
    year?: number,
  ): Promise<BurnRateInsightPayload> {
    const summary = await this.analyticsService.getDashboardSummary(userId, month, year);
    const now = new Date();
    const currentMonth = month || now.getMonth() + 1;
    const currentYear = year || now.getFullYear();

    const daysInMonth = new Date(currentYear, currentMonth, 0).getDate();
    const daysPassed = currentMonth === now.getMonth() + 1 ? Math.max(1, now.getDate()) : daysInMonth;

    const totalIncome = summary.cashFlow.totalIncome;
    const totalExpense = summary.cashFlow.totalExpense;
    const totalBudget = summary.budgetsSummary.totalBudgetLimit;

    const burnRatePercentage = totalBudget > 0
      ? (totalExpense / totalBudget) * 100
      : (totalIncome > 0 ? (totalExpense / totalIncome) * 100 : 0);

    const projectedMonthEndSpend = daysPassed > 0
      ? (totalExpense / daysPassed) * daysInMonth
      : totalExpense;

    let burnStatus = 'HEALTHY';
    if (burnRatePercentage > 100) {
      burnStatus = 'EXCEEDED';
    } else if (burnRatePercentage > (daysPassed / daysInMonth) * 100 + 15) {
      burnStatus = 'WARNING';
    }

    const topCategory = summary.spendingBreakdown.length > 0
      ? summary.spendingBreakdown[0].categoryName
      : 'General Expenses';

    return {
      burnStatus,
      totalMonthlyIncome: totalIncome,
      totalMonthlyExpense: totalExpense,
      burnRatePercentage,
      daysPassedInMonth: daysPassed,
      totalDaysInMonth: daysInMonth,
      projectedMonthEndSpend,
      topExpenseCategory: topCategory,
    };
  }

  /**
   * Tool: Check purchase affordability deterministically against real ledger
   */
  async checkAffordability(
    userId: string,
    amount: number,
    categoryId?: string,
  ): Promise<AffordabilityInsightPayload> {
    const financialSummary = await this.getNetWorthAndBalances(userId);
    const { summary: goalsSummary } = await this.goalsService.findAll(userId);
    const analytics = await this.analyticsService.getDashboardSummary(userId);

    const liquidBuffer = financialSummary.liquidBuffer;
    const postPurchaseLiquidBuffer = liquidBuffer - amount;
    const monthlySavingsTarget = goalsSummary.activeGoalsCount > 0
      ? goalsSummary.totalTargetAmount * 0.05
      : 0;

    const remainingBudgetCommitments = Math.max(
      0,
      analytics.budgetsSummary.totalBudgetLimit - analytics.budgetsSummary.totalBudgetSpent,
    );

    let status: AffordabilityStatus;
    let impactMessage: string;

    if (postPurchaseLiquidBuffer < 0 || amount > liquidBuffer) {
      status = AffordabilityStatus.UNRECOMMENDED;
      impactMessage = `Purchase exceeds available liquid cash reserves (${liquidBuffer.toFixed(2)}). Making this purchase would cause an overdraft or deplete emergency liquidity.`;
    } else if (postPurchaseLiquidBuffer < remainingBudgetCommitments + monthlySavingsTarget) {
      status = AffordabilityStatus.RISKY;
      impactMessage = `Purchase leaves a post-purchase buffer of ${postPurchaseLiquidBuffer.toFixed(2)}, which is below your committed monthly budget allowances and savings goals.`;
    } else if (postPurchaseLiquidBuffer < liquidBuffer * 0.4) {
      status = AffordabilityStatus.MODERATE;
      impactMessage = `Purchase is feasible, but will utilize over 60% of your current liquid buffer. You will retain a safety cushion of ${postPurchaseLiquidBuffer.toFixed(2)}.`;
    } else {
      status = AffordabilityStatus.COMFORTABLE;
      impactMessage = `You can comfortably afford this purchase. After factoring committed expenses and savings goals, you maintain a healthy liquid buffer of ${postPurchaseLiquidBuffer.toFixed(2)}.`;
    }

    return {
      status,
      purchaseAmount: amount,
      currentLiquidBuffer: liquidBuffer,
      postPurchaseLiquidBuffer: Math.max(0, postPurchaseLiquidBuffer),
      committedBillsThisMonth: remainingBudgetCommitments,
      monthlySavingsTarget,
      budgetImpactMessage: impactMessage,
    };
  }

  /**
   * Tool: Retrieve grounded Savings Goal Milestones and Required Pace
   */
  async getSavingsGoalsPace(userId: string): Promise<SavingsGoalInsightPayload> {
    const { goals, summary } = await this.goalsService.findAll(userId);
    const activeGoals = goals.filter((g) => !g.isCompleted);

    let totalDailyRequired = 0;
    let totalMonthlyRequired = 0;

    for (const g of activeGoals) {
      const targetDate = new Date(g.targetDate);
      const now = new Date();
      const diffTime = targetDate.getTime() - now.getTime();
      const diffDays = Math.max(1, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
      const remainingAmount = Math.max(0, g.targetAmount - g.currentAmount);

      const daily = remainingAmount / diffDays;
      totalDailyRequired += daily;
      totalMonthlyRequired += daily * 30.44;
    }

    return {
      goalCount: goals.length,
      activeGoalNames: activeGoals.map((g) => g.name),
      totalSaved: summary.totalCurrentAmount,
      totalTarget: summary.totalTargetAmount,
      overallProgressPercentage: summary.overallProgressPercentage,
      requiredDailySavings: totalDailyRequired,
      requiredMonthlySavings: totalMonthlyRequired,
    };
  }

  /**
   * Tool: Search transactions in user ledger
   */
  async searchTransactions(
    userId: string,
    query?: string,
    limit: number = 5,
  ): Promise<any[]> {
    const supabase = this.supabaseService.getAdminClient();
    let q = supabase
      .from('transactions')
      .select('id, amount, type, description, transaction_date, categories:category_id(name)')
      .eq('user_id', userId)
      .order('transaction_date', { ascending: false })
      .limit(limit);

    if (query) {
      q = q.ilike('description', `%${query}%`);
    }

    const { data, error } = await q;
    if (error) {
      this.logger.error(`Error searching transactions: ${error.message}`);
      return [];
    }
    return data || [];
  }
}
