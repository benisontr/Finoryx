import { Test, TestingModule } from '@nestjs/testing';
import { ConfigModule } from '@nestjs/config';
import { SupabaseService } from '../src/database/supabase.service';
import { AuthService } from '../src/modules/auth/auth.service';
import { AccountsService } from '../src/modules/accounts/accounts.service';
import { CategoriesService } from '../src/modules/categories/categories.service';
import { TransactionsService } from '../src/modules/transactions/transactions.service';
import { BudgetsService } from '../src/modules/budgets/budgets.service';
import { GoalsService } from '../src/modules/goals/goals.service';
import { AnalyticsService } from '../src/modules/analytics/analytics.service';
import { AiService } from '../src/modules/ai/ai.service';
import { AiToolsService } from '../src/modules/ai/ai-tools.service';
import { AccountType } from '../src/modules/accounts/dto/create-account.dto';
import { TransactionType } from '../src/modules/transactions/dto/create-transaction.dto';
import { AffordabilityStatus, AiInsightType } from '../src/modules/ai/entities/ai.entity';

describe('E2E Lifecycle Integration Test: Complete Financial Journey', () => {
  let authService: AuthService;
  let accountsService: AccountsService;
  let categoriesService: CategoriesService;
  let transactionsService: TransactionsService;
  let budgetsService: BudgetsService;
  let goalsService: GoalsService;
  let analyticsService: AnalyticsService;
  let aiService: AiService;

  const db = {
    profiles: [] as any[],
    accounts: [] as any[],
    categories: [
      {
        id: 'cat-food',
        user_id: null,
        name: 'Food & Dining',
        icon: 'restaurant',
        color_hex: '#10B981',
        is_system: true,
        type: 'expense',
      },
    ] as any[],
    transactions: [] as any[],
    budgets: [] as any[],
    goals: [] as any[],
  };

  const createMockSupabaseClient = () => {
    return {
      auth: {
        signUp: jest.fn().mockImplementation(async ({ email, password }) => {
          const user = { id: `usr-${Date.now()}`, email, app_metadata: {}, user_metadata: {} };
          return { data: { user, session: { access_token: 'mock-jwt-token' } }, error: null };
        }),
        signInWithPassword: jest.fn().mockImplementation(async ({ email }) => {
          const user = { id: 'usr-e2e', email, app_metadata: {}, user_metadata: {} };
          return { data: { user, session: { access_token: 'mock-jwt-token' } }, error: null };
        }),
        getUser: jest.fn().mockResolvedValue({
          data: { user: { id: 'usr-e2e', email: 'benison@finoryx.io' } },
          error: null,
        }),
      },
      from: jest.fn().mockImplementation((tableName: string) => {
        const table = (db as any)[tableName] || [];
        return {
          insert: jest.fn().mockImplementation((records: any) => {
            const arr = Array.isArray(records) ? records : [records];
            const inserted = arr.map((r) => ({
              id: r.id || `${tableName.substring(0, 3)}-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
              created_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
              current_balance: r.current_balance !== undefined ? String(r.current_balance) : '0.00',
              account_type: r.account_type || 'bank',
              currency: r.currency || 'INR',
              target_amount: r.target_amount !== undefined ? String(r.target_amount) : '0.00',
              current_amount: r.current_amount !== undefined ? String(r.current_amount) : '0.00',
              limit_amount: r.limit_amount !== undefined ? String(r.limit_amount) : '0.00',
              amount: r.amount !== undefined ? String(r.amount) : '0.00',
              fee_amount: r.fee_amount !== undefined ? String(r.fee_amount) : '0.00',
              type: r.type ? r.type.toLowerCase() : 'expense',
              is_archived: false,
              is_completed: false,
              ...r,
            }));
            table.push(...inserted);
            return {
              select: jest.fn().mockReturnValue({
                single: jest.fn().mockResolvedValue({ data: inserted[0], error: null }),
                then: (resolve: any) => resolve({ data: inserted, error: null }),
              }),
              then: (resolve: any) => resolve({ data: inserted, error: null }),
            };
          }),
          upsert: jest.fn().mockImplementation((records: any) => {
            const arr = Array.isArray(records) ? records : [records];
            table.push(...arr);
            return Promise.resolve({ data: arr[0], error: null });
          }),
          select: jest.fn().mockImplementation((fields?: string) => {
            const createFilter = (currentItems: any[]) => {
              const chain: any = {
                eq: jest.fn().mockImplementation((f: string, v: any) => {
                  return createFilter(currentItems.filter((row: any) => row[f] === v));
                }),
                gte: jest.fn().mockImplementation((f: string, v: any) => {
                  return createFilter(currentItems.filter((row: any) => (row[f] || '') >= v));
                }),
                lte: jest.fn().mockImplementation((f: string, v: any) => {
                  return createFilter(currentItems.filter((row: any) => (row[f] || '') <= v));
                }),
                or: jest.fn().mockImplementation(() => chain),
                order: jest.fn().mockImplementation(() => chain),
                limit: jest.fn().mockImplementation(() => chain),
                single: jest.fn().mockImplementation(async () => ({
                  data: currentItems[0] || null,
                  error: currentItems[0] ? null : { message: 'Not found' },
                })),
                then: (resolve: any) => resolve({ data: currentItems, error: null }),
              };
              return chain;
            };
            return createFilter(table);
          }),
          update: jest.fn().mockImplementation((updates: any) => {
            const createUpdateFilter = (conditions: Record<string, any>) => {
              const chain: any = {
                eq: jest.fn().mockImplementation((field: string, val: any) => {
                  conditions[field] = val;
                  // Update all matching rows in table
                  for (const row of table) {
                    let matches = true;
                    for (const [k, v] of Object.entries(conditions)) {
                      if (row[k] !== v) matches = false;
                    }
                    if (matches) {
                      Object.assign(row, updates);
                      row.updated_at = new Date().toISOString();
                    }
                  }
                  return createUpdateFilter(conditions);
                }),
                select: jest.fn().mockReturnValue({
                  single: jest.fn().mockImplementation(async () => {
                    const found = table.find((row: any) => {
                      for (const [k, v] of Object.entries(conditions)) {
                        if (row[k] !== v) return false;
                      }
                      return true;
                    });
                    return { data: found || null, error: null };
                  }),
                }),
                then: (resolve: any) => resolve({ data: table, error: null }),
              };
              return chain;
            };
            return createUpdateFilter({});
          }),
          delete: jest.fn().mockImplementation(() => {
            return {
              eq: jest.fn().mockImplementation((field: string, val: any) => {
                const idx = table.findIndex((row: any) => row[field] === val);
                if (idx !== -1) table.splice(idx, 1);
                return {
                  then: (resolve: any) => resolve({ data: null, error: null }),
                };
              }),
            };
          }),
        };
      }),
    };
  };

  const mockSupabaseInstance = createMockSupabaseClient();
  const mockSupabaseService = {
    getClient: jest.fn().mockReturnValue(mockSupabaseInstance),
    getAdminClient: jest.fn().mockReturnValue(mockSupabaseInstance),
  };

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          load: [() => ({ port: 3000, apiPrefix: 'api/v1' })],
        }),
      ],
      providers: [
        AuthService,
        AccountsService,
        CategoriesService,
        TransactionsService,
        BudgetsService,
        GoalsService,
        AnalyticsService,
        AiService,
        AiToolsService,
        { provide: SupabaseService, useValue: mockSupabaseService },
      ],
    }).compile();

    authService = module.get<AuthService>(AuthService);
    accountsService = module.get<AccountsService>(AccountsService);
    categoriesService = module.get<CategoriesService>(CategoriesService);
    transactionsService = module.get<TransactionsService>(TransactionsService);
    budgetsService = module.get<BudgetsService>(BudgetsService);
    goalsService = module.get<GoalsService>(GoalsService);
    analyticsService = module.get<AnalyticsService>(AnalyticsService);
    aiService = module.get<AiService>(AiService);
  });

  const userId = 'usr-e2e';
  let bankAccountId: string;
  let cashAccountId: string;
  let creditCardAccountId: string;
  let foodCategoryId: string;
  let emergencyGoalId: string;

  it('Step 1: User Signup & Authentication', async () => {
    const authResult = await authService.signUp({
      email: 'benison@finoryx.io',
      password: 'SecurePassword123!',
      fullName: 'Benison T R',
      baseCurrency: 'INR',
    });

    expect(authResult.user).toBeDefined();
    expect(authResult.session).toBeDefined();
  });

  it('Step 2: Account Creation & Initial Net Worth', async () => {
    const bank = await accountsService.createAccount(userId, {
      name: 'HDFC Salary Bank',
      accountType: AccountType.BANK,
      currency: 'INR',
      initialBalance: 100000,
    });
    bankAccountId = bank.id;
    expect(bank.currentBalance).toBe(100000);

    const cash = await accountsService.createAccount(userId, {
      name: 'Physical Cash Wallet',
      accountType: AccountType.CASH,
      currency: 'INR',
      initialBalance: 5000,
    });
    cashAccountId = cash.id;
    expect(cash.currentBalance).toBe(5000);

    const card = await accountsService.createAccount(userId, {
      name: 'ICICI Amazon Pay Credit Card',
      accountType: AccountType.CREDIT_CARD,
      currency: 'INR',
      initialBalance: 15000,
    });
    creditCardAccountId = card.id;
    expect(card.currentBalance).toBe(15000);

    const summary = await accountsService.getAccountsSummary(userId);
    expect(summary.totalAssets).toBe(105000);
    expect(summary.totalLiabilities).toBe(15000);
    expect(summary.totalNetWorth).toBe(90000);
  });

  it('Step 3: Category Taxonomy Configuration', async () => {
    const categories = await categoriesService.getCategories(userId);
    expect(categories.length).toBeGreaterThan(0);

    const foodCat = categories.find((c) => c.name.toLowerCase().includes('food')) || categories[0];
    foodCategoryId = foodCat.id;
    expect(foodCategoryId).toBeDefined();
  });

  it('Step 4: Transactions & Double-Entry Transfers', async () => {
    const expenseTx = await transactionsService.createTransaction(userId, {
      accountId: bankAccountId,
      categoryId: foodCategoryId,
      type: TransactionType.EXPENSE,
      amount: 3000,
      description: 'Weekly Grocery Shopping',
      transactionDate: new Date().toISOString().split('T')[0],
    });
    expect(expenseTx.amount).toBe(3000);

    const updatedBank = await accountsService.getAccountById(userId, bankAccountId);
    expect(updatedBank.currentBalance).toBe(97000);

    const transferTx = await transactionsService.createTransaction(userId, {
      accountId: bankAccountId,
      destinationAccountId: cashAccountId,
      type: TransactionType.TRANSFER,
      amount: 10000,
      feeAmount: 50,
      description: 'ATM Cash Withdrawal',
      transactionDate: new Date().toISOString().split('T')[0],
    });

    expect(transferTx.type).toBe('transfer');

    const postTransferBank = await accountsService.getAccountById(userId, bankAccountId);
    expect(postTransferBank.currentBalance).toBe(86950);

    const postTransferCash = await accountsService.getAccountById(userId, cashAccountId);
    expect(postTransferCash.currentBalance).toBe(15000);
  });

  it('Step 5: Category Budgeting & Burn Rate Tracking', async () => {
    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();

    const budget = await budgetsService.createBudget(userId, {
      categoryId: foodCategoryId,
      month: currentMonth,
      year: currentYear,
      limitAmount: 10000,
    });

    expect(budget.limitAmount).toBe(10000);

    const budgets = await budgetsService.getBudgets(userId, currentMonth, currentYear);
    expect(budgets.length).toBeGreaterThan(0);
    const foodBudget = budgets.find((b) => b.categoryId === foodCategoryId);
    expect(foodBudget).toBeDefined();
    expect(foodBudget?.spentAmount).toBe(3000);
    expect(foodBudget?.remainingAmount).toBe(7000);
    expect(foodBudget?.spentPercentage).toBe(30);
  });

  it('Step 6: Financial Goals & Atomic Balance Contribution', async () => {
    const goal = await goalsService.create(userId, {
      name: 'Emergency Fund',
      targetAmount: 100000,
      targetDate: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000).toISOString(),
      linkedAccountId: bankAccountId,
    });
    emergencyGoalId = goal.id;
    expect(goal.currentAmount).toBe(0);

    const updatedGoal = await goalsService.contribute(userId, emergencyGoalId, {
      amount: 20000,
      sourceAccountId: bankAccountId,
    });

    expect(updatedGoal.currentAmount).toBe(20000);
    expect(updatedGoal.progressPercentage).toBe(20);

    const postGoalBank = await accountsService.getAccountById(userId, bankAccountId);
    expect(postGoalBank.currentBalance).toBe(66950);
  });

  it('Step 7: Dashboard & Analytics Aggregation', async () => {
    const dashboard = await analyticsService.getDashboardSummary(userId);

    expect(dashboard.netWorth).toBeDefined();
    // Assets: Bank (66950) + Cash (15000) = 81950. Liabilities: 15000. Net Worth = 66950.
    expect(dashboard.netWorth.totalAssets).toBe(81950);
    expect(dashboard.netWorth.totalLiabilities).toBe(15000);
    expect(dashboard.netWorth.netWorth).toBe(66950);
    expect(dashboard.cashFlow.totalExpense).toBeGreaterThanOrEqual(3000);
  });

  it('Step 8: AI Copilot Grounded Conversational Intelligence', async () => {
    const affordResponse = await aiService.processChat(userId, {
      message: 'Can I afford ₹15,000 for a gaming chair?',
    });

    expect(affordResponse.toolsUsed).toContain('check_affordability');
    expect(affordResponse.structuredInsight?.type).toBe(AiInsightType.AFFORDABILITY_CHECK);
    expect(affordResponse.structuredInsight?.affordability?.status).toBe(AffordabilityStatus.COMFORTABLE);

    const burnResponse = await aiService.processChat(userId, {
      message: 'How is my spending pacing and burn rate this month?',
    });
    expect(burnResponse.toolsUsed).toContain('get_monthly_burn_rate');
    expect(burnResponse.structuredInsight?.type).toBe(AiInsightType.BURN_RATE_CHECK);

    const goalResponse = await aiService.processChat(userId, {
      message: 'How is my savings pace for my Emergency Fund?',
    });
    expect(goalResponse.toolsUsed).toContain('get_savings_goals_pace');
    expect(goalResponse.structuredInsight?.type).toBe(AiInsightType.SAVINGS_GOALS_PACE);
    expect(goalResponse.structuredInsight?.savingsGoals?.totalSaved).toBe(20000);
  });
});
