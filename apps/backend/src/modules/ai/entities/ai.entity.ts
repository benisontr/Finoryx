export enum AiInsightType {
  AFFORDABILITY_CHECK = 'AFFORDABILITY_CHECK',
  BURN_RATE_CHECK = 'BURN_RATE_CHECK',
  SAVINGS_GOALS_PACE = 'SAVINGS_GOALS_PACE',
  FINANCIAL_SUMMARY = 'FINANCIAL_SUMMARY',
  TRANSACTION_SEARCH = 'TRANSACTION_SEARCH',
  GENERAL_INSIGHT = 'GENERAL_INSIGHT',
}

export enum AffordabilityStatus {
  COMFORTABLE = 'COMFORTABLE',
  MODERATE = 'MODERATE',
  RISKY = 'RISKY',
  UNRECOMMENDED = 'UNRECOMMENDED',
}

export interface AffordabilityInsightPayload {
  status: AffordabilityStatus;
  purchaseAmount: number;
  currentLiquidBuffer: number;
  postPurchaseLiquidBuffer: number;
  committedBillsThisMonth: number;
  monthlySavingsTarget: number;
  budgetImpactMessage: string;
}

export interface BurnRateInsightPayload {
  burnStatus: string;
  totalMonthlyIncome: number;
  totalMonthlyExpense: number;
  burnRatePercentage: number;
  daysPassedInMonth: number;
  totalDaysInMonth: number;
  projectedMonthEndSpend: number;
  topExpenseCategory: string;
}

export interface SavingsGoalInsightPayload {
  goalCount: number;
  activeGoalNames: string[];
  totalSaved: number;
  totalTarget: number;
  overallProgressPercentage: number;
  requiredDailySavings: number;
  requiredMonthlySavings: number;
}

export interface FinancialSummaryInsightPayload {
  netWorth: number;
  totalAssets: number;
  totalLiabilities: number;
  liquidBuffer: number;
  monthlySavingsRate: number;
}

export interface AiStructuredInsight {
  type: AiInsightType;
  title: string;
  summary: string;
  statusColor?: string;
  affordability?: AffordabilityInsightPayload;
  burnRate?: BurnRateInsightPayload;
  savingsGoals?: SavingsGoalInsightPayload;
  financialSummary?: FinancialSummaryInsightPayload;
}

export interface AiChatResponse {
  message: string;
  timestamp: string;
  toolsUsed: string[];
  structuredInsight?: AiStructuredInsight;
}
