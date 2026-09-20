import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { AiService } from './ai.service';
import { AiToolsService } from './ai-tools.service';
import { SupabaseService } from '../../database/supabase.service';
import { AnalyticsService } from '../analytics/analytics.service';
import { GoalsService } from '../goals/goals.service';
import { BudgetsService } from '../budgets/budgets.service';
import { AffordabilityStatus, AiInsightType } from './entities/ai.entity';

describe('AiService & AiToolsService', () => {
  let aiService: AiService;
  let aiToolsService: AiToolsService;

  const mockAccounts = [
    {
      id: 'acc-1',
      name: 'Main Bank',
      account_type: 'bank',
      current_balance: '50000.00',
    },
    {
      id: 'acc-2',
      name: 'Credit Card',
      account_type: 'credit_card',
      current_balance: '-10000.00',
    },
  ];

  const mockSupabaseService = {
    getAdminClient: jest.fn().mockReturnValue({
      from: jest.fn().mockImplementation((tableName: string) => ({
        select: jest.fn().mockReturnValue({
          eq: jest.fn().mockReturnValue({
            order: jest.fn().mockReturnValue({
              limit: jest.fn().mockResolvedValue({ data: [], error: null }),
            }),
            then: (resolve: any) => resolve({ data: mockAccounts, error: null }),
          }),
        }),
      })),
    }),
  };

  const mockAnalyticsService = {
    getDashboardSummary: jest.fn().mockResolvedValue({
      netWorth: { totalAssets: 50000, totalLiabilities: 10000, netWorth: 40000 },
      cashFlow: { totalIncome: 60000, totalExpense: 25000, netSavings: 35000, savingsRate: 58.3 },
      budgetsSummary: {
        totalBudgetLimit: 30000,
        totalBudgetSpent: 25000,
        overallPercentage: 83.3,
        warningCount: 0,
        exceededCount: 0,
        criticalBudgets: [],
      },
      spendingBreakdown: [
        { categoryId: 'cat-1', categoryName: 'Food & Dining', categoryColorHex: '#10B981', amount: 15000, percentage: 60 },
      ],
      cashFlowTrends: [],
    }),
  };

  const mockGoalsService = {
    findAll: jest.fn().mockResolvedValue({
      goals: [
        {
          id: 'goal-1',
          name: 'Emergency Fund',
          targetAmount: 50000.00,
          currentAmount: 20000.00,
          targetDate: new Date(Date.now() + 100 * 24 * 60 * 60 * 1000).toISOString(),
          isCompleted: false,
        },
      ],
      summary: {
        totalTargetAmount: 100000,
        totalCurrentAmount: 40000,
        totalRemainingAmount: 60000,
        overallProgressPercentage: 40,
        activeGoalsCount: 1,
        completedGoalsCount: 0,
      },
    }),
  };

  const mockBudgetsService = {
    getBudgets: jest.fn().mockResolvedValue([]),
  };

  const mockConfigService = {
    get: jest.fn().mockImplementation((key: string, defaultValue?: any) => defaultValue),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiService,
        AiToolsService,
        { provide: SupabaseService, useValue: mockSupabaseService },
        { provide: AnalyticsService, useValue: mockAnalyticsService },
        { provide: GoalsService, useValue: mockGoalsService },
        { provide: BudgetsService, useValue: mockBudgetsService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    aiService = module.get<AiService>(AiService);
    aiToolsService = module.get<AiToolsService>(AiToolsService);
  });

  describe('Grounded Tools Execution', () => {
    it('should calculate grounded Net Worth and liquid buffer', async () => {
      const summary = await aiToolsService.getNetWorthAndBalances('user-123');
      expect(summary.netWorth).toBe(40000);
      expect(summary.totalAssets).toBe(50000);
      expect(summary.totalLiabilities).toBe(10000);
      expect(summary.liquidBuffer).toBe(50000);
      expect(summary.monthlySavingsRate).toBe(58.3);
    });

    it('should evaluate comfortable affordability for a small purchase', async () => {
      const result = await aiToolsService.checkAffordability('user-123', 5000);
      expect(result.status).toBe(AffordabilityStatus.COMFORTABLE);
      expect(result.currentLiquidBuffer).toBe(50000);
      expect(result.postPurchaseLiquidBuffer).toBe(45000);
      expect(result.budgetImpactMessage).toContain('comfortably afford');
    });

    it('should evaluate unrecommended affordability if amount exceeds liquid buffer', async () => {
      const result = await aiToolsService.checkAffordability('user-123', 60000);
      expect(result.status).toBe(AffordabilityStatus.UNRECOMMENDED);
      expect(result.budgetImpactMessage).toContain('exceeds available liquid cash');
    });

    it('should calculate monthly burn rate and pacing status', async () => {
      const burnRate = await aiToolsService.getMonthlyBurnRate('user-123');
      expect(burnRate.totalMonthlyIncome).toBe(60000);
      expect(burnRate.totalMonthlyExpense).toBe(25000);
      expect(burnRate.topExpenseCategory).toBe('Food & Dining');
      expect(burnRate.burnRatePercentage).toBeGreaterThan(0);
    });

    it('should compute required savings daily pace', async () => {
      const pace = await aiToolsService.getSavingsGoalsPace('user-123');
      expect(pace.goalCount).toBe(1);
      expect(pace.activeGoalNames).toContain('Emergency Fund');
      expect(pace.requiredDailySavings).toBeGreaterThan(0);
    });
  });

  describe('Conversational Intent Dispatching', () => {
    it('should process affordability natural language questions', async () => {
      const response = await aiService.processChat('user-123', {
        message: 'Can I afford ₹15,000 for a new monitor?',
      });

      expect(response.toolsUsed).toContain('check_affordability');
      expect(response.structuredInsight).toBeDefined();
      expect(response.structuredInsight?.type).toBe(AiInsightType.AFFORDABILITY_CHECK);
      expect(response.message).toContain('Based on your real-time ledger balance');
    });

    it('should process burn rate & spending questions', async () => {
      const response = await aiService.processChat('user-123', {
        message: 'How is my spending burn rate and pacing this month?',
      });

      expect(response.toolsUsed).toContain('get_monthly_burn_rate');
      expect(response.structuredInsight?.type).toBe(AiInsightType.BURN_RATE_CHECK);
      expect(response.message).toContain('Food & Dining');
    });

    it('should process savings goal pace questions', async () => {
      const response = await aiService.processChat('user-123', {
        message: 'How is my savings pace for my Emergency Fund?',
      });

      expect(response.toolsUsed).toContain('get_savings_goals_pace');
      expect(response.structuredInsight?.type).toBe(AiInsightType.SAVINGS_GOALS_PACE);
      expect(response.message).toContain('Emergency Fund');
    });

    it('should return financial snapshot for general overview queries', async () => {
      const response = await aiService.processChat('user-123', {
        message: 'What is my current net worth and financial summary?',
      });

      expect(response.toolsUsed).toContain('get_net_worth_and_balances');
      expect(response.structuredInsight?.type).toBe(AiInsightType.FINANCIAL_SUMMARY);
    });

    it('should generate proactive insights for the dashboard', async () => {
      const insights = await aiService.getProactiveInsights('user-123');
      expect(insights.length).toBeGreaterThan(0);
      expect(insights[0].burnRate).toBeDefined();
    });
  });
});
