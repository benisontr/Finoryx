import { Test, TestingModule } from '@nestjs/testing';
import { BudgetsService } from './budgets.service';
import { SupabaseService } from '../../database/supabase.service';
import { BurnRateStatus } from './entities/budget.entity';

describe('BudgetsService', () => {
  let service: BudgetsService;
  let mockSupabaseService: Partial<SupabaseService>;

  const mockBudgetRow = {
    id: 'budget-1',
    user_id: 'user-123',
    category_id: 'cat-food',
    month: 9,
    year: 2026,
    limit_amount: '10000.00',
    notify_threshold_pct: 80,
    created_at: '2026-09-01T00:00:00.000Z',
    updated_at: '2026-09-01T00:00:00.000Z',
    categories: {
      name: 'Food & Dining',
      icon: 'restaurant',
      color_hex: '#EF4444',
    },
  };

  beforeEach(async () => {
    mockSupabaseService = {
      getAdminClient: jest.fn().mockReturnValue({
        from: jest.fn().mockImplementation((tableName: string) => {
          if (tableName === 'budgets') {
            return {
              select: jest.fn().mockReturnValue({
                eq: jest.fn().mockReturnValue({
                  eq: jest.fn().mockReturnValue({
                    eq: jest.fn().mockResolvedValue({
                      data: [mockBudgetRow],
                      error: null,
                    }),
                  }),
                }),
              }),
              insert: jest.fn().mockReturnValue({
                select: jest.fn().mockReturnValue({
                  single: jest.fn().mockResolvedValue({
                    data: mockBudgetRow,
                    error: null,
                  }),
                }),
              }),
              update: jest.fn().mockReturnValue({
                eq: jest.fn().mockReturnValue({
                  eq: jest.fn().mockReturnValue({
                    select: jest.fn().mockReturnValue({
                      single: jest.fn().mockResolvedValue({
                        data: mockBudgetRow,
                        error: null,
                      }),
                    }),
                  }),
                }),
              }),
              delete: jest.fn().mockReturnValue({
                eq: jest.fn().mockReturnValue({
                  eq: jest.fn().mockResolvedValue({ error: null }),
                }),
              }),
            };
          }

          if (tableName === 'transactions') {
            return {
              select: jest.fn().mockReturnValue({
                eq: jest.fn().mockReturnValue({
                  eq: jest.fn().mockReturnValue({
                    gte: jest.fn().mockReturnValue({
                      lte: jest.fn().mockResolvedValue({
                        data: [
                          { category_id: 'cat-food', amount: '3500.00', fee_amount: '0.00' },
                          { category_id: 'cat-food', amount: '1500.00', fee_amount: '0.00' },
                        ],
                        error: null,
                      }),
                    }),
                  }),
                }),
              }),
            };
          }
        }),
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BudgetsService,
        { provide: SupabaseService, useValue: mockSupabaseService },
      ],
    }).compile();

    service = module.get<BudgetsService>(BudgetsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should calculate budget actual spent, remaining, and percentage correctly', async () => {
    const budgets = await service.getBudgets('user-123', 9, 2026);

    expect(budgets).toBeDefined();
    expect(budgets.length).toBe(1);
    expect(budgets[0].limitAmount).toBe(10000.0);
    expect(budgets[0].spentAmount).toBe(5000.0); // 3500 + 1500
    expect(budgets[0].remainingAmount).toBe(5000.0);
    expect(budgets[0].spentPercentage).toBe(50.0);
  });

  it('should create a new budget entry', async () => {
    const result = await service.createBudget('user-123', {
      categoryId: 'cat-food',
      month: 9,
      year: 2026,
      limitAmount: 10000,
    });

    expect(result).toBeDefined();
    expect(result.limitAmount).toBe(10000);
  });

  it('should delete a budget entry successfully', async () => {
    const result = await service.deleteBudget('user-123', 'budget-1');
    expect(result.success).toBe(true);
  });
});
