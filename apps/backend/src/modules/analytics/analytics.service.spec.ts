import { Test, TestingModule } from '@nestjs/testing';
import { AnalyticsService } from './analytics.service';
import { SupabaseService } from '../../database/supabase.service';
import { BudgetsService } from '../budgets/budgets.service';
import { GoalsService } from '../goals/goals.service';
import { BurnRateStatus } from '../budgets/entities/budget.entity';
import { GoalPaceStatus } from '../goals/entities/goal.entity';

describe('AnalyticsService', () => {
  let service: AnalyticsService;
  let mockSupabase: any;
  let mockBudgetsService: any;
  let mockGoalsService: any;

  beforeEach(async () => {
    mockSupabase = {
      from: jest.fn().mockReturnThis(),
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      gte: jest.fn().mockReturnThis(),
      lte: jest.fn().mockReturnThis(),
    };

    const mockSupabaseService = {
      getAdminClient: jest.fn().mockReturnValue(mockSupabase),
    };

    mockBudgetsService = {
      getBudgets: jest.fn().mockResolvedValue([
        {
          id: 'b-1',
          categoryId: 'c-1',
          limitAmount: 500,
          spentAmount: 450,
          burnRateStatus: BurnRateStatus.WARNING,
        },
      ]),
    };

    mockGoalsService = {
      findAll: jest.fn().mockResolvedValue({
        goals: [
          {
            id: 'g-1',
            name: 'Emergency Fund',
            targetAmount: 5000,
            currentAmount: 2500,
            isCompleted: false,
            paceStatus: GoalPaceStatus.ON_TRACK,
          },
        ],
        summary: {
          totalTargetAmount: 5000,
          totalCurrentAmount: 2500,
          totalRemainingAmount: 2500,
          overallProgressPercentage: 50,
          activeGoalsCount: 1,
          completedGoalsCount: 0,
        },
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AnalyticsService,
        {
          provide: SupabaseService,
          useValue: mockSupabaseService,
        },
        {
          provide: BudgetsService,
          useValue: mockBudgetsService,
        },
        {
          provide: GoalsService,
          useValue: mockGoalsService,
        },
      ],
    }).compile();

    service = module.get<AnalyticsService>(AnalyticsService);
  });

  it('should aggregate net worth, cash flow, category breakdown, budgets and goals', async () => {
    const mockAccounts = [
      { id: 'a-1', name: 'Checking', type: 'CHECKING', current_balance: '5000.00' },
      { id: 'a-2', name: 'Credit Card', type: 'CREDIT_CARD', current_balance: '1200.00' },
    ];

    const mockMonthTxs = [
      { id: 't-1', amount: '4000.00', type: 'INCOME', category_id: null },
      {
        id: 't-2',
        amount: '600.00',
        type: 'EXPENSE',
        category_id: 'cat-food',
        categories: { id: 'cat-food', name: 'Food & Dining', icon: 'restaurant', color_hex: '#EF4444' },
      },
      {
        id: 't-3',
        amount: '400.00',
        type: 'EXPENSE',
        category_id: 'cat-util',
        categories: { id: 'cat-util', name: 'Utilities', icon: 'bolt', color_hex: '#3B82F6' },
      },
    ];

    mockSupabase.eq
      .mockResolvedValueOnce({ data: mockAccounts, error: null }) // accounts
      .mockReturnValue(mockSupabase); // chained for transactions
    mockSupabase.lte
      .mockResolvedValueOnce({ data: mockMonthTxs, error: null }) // target month transactions
      .mockResolvedValue({ data: [], error: null }); // trend transactions

    const result = await service.getDashboardSummary('user-1', 6, 2026);

    // Net worth: 5000 (Checking) - 1200 (Credit Card) = 3800
    expect(result.netWorth.netWorth).toBe(3800);
    expect(result.netWorth.totalAssets).toBe(5000);
    expect(result.netWorth.totalLiabilities).toBe(1200);

    // Cash flow: 4000 Income, 1000 Expense -> Net: 3000 -> Savings Rate: 75%
    expect(result.cashFlow.totalIncome).toBe(4000);
    expect(result.cashFlow.totalExpense).toBe(1000);
    expect(result.cashFlow.netCashFlow).toBe(3000);
    expect(result.cashFlow.savingsRate).toBe(75);

    // Category breakdown: Food (60%), Utilities (40%)
    expect(result.spendingBreakdown).toHaveLength(2);
    expect(result.spendingBreakdown[0].categoryName).toBe('Food & Dining');
    expect(result.spendingBreakdown[0].amount).toBe(600);
    expect(result.spendingBreakdown[0].percentage).toBe(60);

    // Budgets & Goals
    expect(result.budgetsSummary.warningCount).toBe(1);
    expect(result.goalsSummary.totalSaved).toBe(2500);
    expect(result.cashFlowTrends).toHaveLength(6);
  });
});
