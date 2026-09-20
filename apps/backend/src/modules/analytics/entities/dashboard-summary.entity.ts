import { BudgetEntity } from '../../budgets/entities/budget.entity';
import { GoalEntity } from '../../goals/entities/goal.entity';

export interface CategorySpendingItem {
  categoryId: string;
  categoryName: string;
  categoryIcon: string;
  categoryColorHex: string;
  amount: number;
  percentage: number;
}

export interface CashFlowTrendPoint {
  month: number;
  year: number;
  label: string;
  income: number;
  expense: number;
  netCashFlow: number;
}

export class DashboardSummaryEntity {
  netWorth: {
    netWorth: number;
    totalAssets: number;
    totalLiabilities: number;
    accountsCount: number;
  };
  cashFlow: {
    month: number;
    year: number;
    totalIncome: number;
    totalExpense: number;
    netCashFlow: number;
    savingsRate: number;
  };
  spendingBreakdown: CategorySpendingItem[];
  budgetsSummary: {
    totalBudgetLimit: number;
    totalBudgetSpent: number;
    overallPercentage: number;
    warningCount: number;
    exceededCount: number;
    criticalBudgets: BudgetEntity[];
  };
  goalsSummary: {
    totalTarget: number;
    totalSaved: number;
    overallProgress: number;
    activeCount: number;
    completedCount: number;
    nearestGoal?: GoalEntity;
  };
  cashFlowTrends: CashFlowTrendPoint[];
}
