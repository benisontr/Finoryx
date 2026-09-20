import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { TransactionsService } from '../src/modules/transactions/transactions.service';
import { GoalsService } from '../src/modules/goals/goals.service';
import { BudgetsService } from '../src/modules/budgets/budgets.service';
import { AiToolsService } from '../src/modules/ai/ai-tools.service';
import { AnalyticsService } from '../src/modules/analytics/analytics.service';
import { SupabaseService } from '../src/database/supabase.service';
import { TransactionType } from '../src/modules/transactions/dto/create-transaction.dto';
import { AffordabilityStatus } from '../src/modules/ai/entities/ai.entity';

describe('Mathematical Invariants & Edge Case Validation', () => {
  let transactionsService: TransactionsService;
  let goalsService: GoalsService;
  let budgetsService: BudgetsService;
  let aiToolsService: AiToolsService;

  const createMockChain = (data: any = null, error: any = null) => {
    const chain: any = {
      select: jest.fn().mockImplementation(() => chain),
      eq: jest.fn().mockImplementation(() => chain),
      gte: jest.fn().mockImplementation(() => chain),
      lte: jest.fn().mockImplementation(() => chain),
      order: jest.fn().mockImplementation(() => chain),
      limit: jest.fn().mockImplementation(() => chain),
      single: jest.fn().mockResolvedValue({ data, error }),
      then: (resolve: any) => resolve({ data: Array.isArray(data) ? data : (data ? [data] : []), error }),
    };
    return chain;
  };

  const mockSupabase = {
    from: jest.fn().mockImplementation((tableName: string) => {
      if (tableName === 'accounts') {
        return createMockChain({ id: 'acc-1', user_id: 'user-1', current_balance: '1000.00', account_type: 'bank' });
      }
      if (tableName === 'goals') {
        return createMockChain([]);
      }
      if (tableName === 'budgets') {
        return createMockChain([]);
      }
      if (tableName === 'transactions') {
        return createMockChain([]);
      }
      return createMockChain();
    }),
  };

  const mockAnalytics = {
    getDashboardSummary: jest.fn().mockResolvedValue({
      netWorth: { totalAssets: 0, totalLiabilities: 5000, netWorth: -5000 },
      cashFlow: { totalIncome: 0, totalExpense: 1000, savingsRate: 0 },
      budgetsSummary: { totalBudgetLimit: 0, totalBudgetSpent: 1000, warningCount: 1, exceededCount: 1 },
      spendingBreakdown: [],
      cashFlowTrends: [],
    }),
  };

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TransactionsService,
        GoalsService,
        BudgetsService,
        AiToolsService,
        { provide: SupabaseService, useValue: { getAdminClient: () => mockSupabase, getClient: () => mockSupabase } },
        { provide: AnalyticsService, useValue: mockAnalytics },
      ],
    }).compile();

    transactionsService = module.get<TransactionsService>(TransactionsService);
    goalsService = module.get<GoalsService>(GoalsService);
    budgetsService = module.get<BudgetsService>(BudgetsService);
    aiToolsService = module.get<AiToolsService>(AiToolsService);
  });

  describe('1. Double-Entry Transfer Invariants', () => {
    it('should reject transfers where source and destination account are identical', async () => {
      await expect(
        transactionsService.createTransaction('user-1', {
          accountId: 'acc-same',
          destinationAccountId: 'acc-same',
          type: TransactionType.TRANSFER,
          amount: 500,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject transfer missing destination account', async () => {
      await expect(
        transactionsService.createTransaction('user-1', {
          accountId: 'acc-1',
          type: TransactionType.TRANSFER,
          amount: 500,
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('2. Savings Goals Timeline & Account Linking Invariants', () => {
    it('should reject goal creation when linked account does not belong to user', async () => {
      mockSupabase.from.mockReturnValueOnce(createMockChain(null, { message: 'Not found' }));

      await expect(
        goalsService.create('user-1', {
          name: 'Invalid Goal',
          targetAmount: 50000,
          targetDate: new Date(Date.now() + 1000000).toISOString(),
          linkedAccountId: 'acc-nonexistent',
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('3. AI Affordability Engine with Zero Reserves', () => {
    it('should mark purchase as UNRECOMMENDED when user holds ₹0 liquid cash', async () => {
      mockSupabase.from.mockImplementationOnce(() =>
        createMockChain({ id: 'acc-1', user_id: 'user-1', current_balance: '0.00', account_type: 'bank' }),
      );

      const result = await aiToolsService.checkAffordability('user-1', 1500);

      expect(result.status).toBe(AffordabilityStatus.UNRECOMMENDED);
      expect(result.currentLiquidBuffer).toBe(0);
      expect(result.budgetImpactMessage).toContain('exceeds available liquid cash');
    });
  });
});
