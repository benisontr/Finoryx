"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const testing_1 = require("@nestjs/testing");
const config_1 = require("@nestjs/config");
const supabase_service_1 = require("../src/database/supabase.service");
const auth_service_1 = require("../src/modules/auth/auth.service");
const accounts_service_1 = require("../src/modules/accounts/accounts.service");
const categories_service_1 = require("../src/modules/categories/categories.service");
const transactions_service_1 = require("../src/modules/transactions/transactions.service");
const budgets_service_1 = require("../src/modules/budgets/budgets.service");
const goals_service_1 = require("../src/modules/goals/goals.service");
const analytics_service_1 = require("../src/modules/analytics/analytics.service");
const ai_service_1 = require("../src/modules/ai/ai.service");
const ai_tools_service_1 = require("../src/modules/ai/ai-tools.service");
const create_account_dto_1 = require("../src/modules/accounts/dto/create-account.dto");
const create_transaction_dto_1 = require("../src/modules/transactions/dto/create-transaction.dto");
const ai_entity_1 = require("../src/modules/ai/entities/ai.entity");
describe('E2E Lifecycle Integration Test: Complete Financial Journey', () => {
    let authService;
    let accountsService;
    let categoriesService;
    let transactionsService;
    let budgetsService;
    let goalsService;
    let analyticsService;
    let aiService;
    const db = {
        profiles: [],
        accounts: [],
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
        ],
        transactions: [],
        budgets: [],
        goals: [],
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
            from: jest.fn().mockImplementation((tableName) => {
                const table = db[tableName] || [];
                return {
                    insert: jest.fn().mockImplementation((records) => {
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
                                then: (resolve) => resolve({ data: inserted, error: null }),
                            }),
                            then: (resolve) => resolve({ data: inserted, error: null }),
                        };
                    }),
                    upsert: jest.fn().mockImplementation((records) => {
                        const arr = Array.isArray(records) ? records : [records];
                        table.push(...arr);
                        return Promise.resolve({ data: arr[0], error: null });
                    }),
                    select: jest.fn().mockImplementation((fields) => {
                        const createFilter = (currentItems) => {
                            const chain = {
                                eq: jest.fn().mockImplementation((f, v) => {
                                    return createFilter(currentItems.filter((row) => row[f] === v));
                                }),
                                gte: jest.fn().mockImplementation((f, v) => {
                                    return createFilter(currentItems.filter((row) => (row[f] || '') >= v));
                                }),
                                lte: jest.fn().mockImplementation((f, v) => {
                                    return createFilter(currentItems.filter((row) => (row[f] || '') <= v));
                                }),
                                or: jest.fn().mockImplementation(() => chain),
                                order: jest.fn().mockImplementation(() => chain),
                                limit: jest.fn().mockImplementation(() => chain),
                                single: jest.fn().mockImplementation(async () => ({
                                    data: currentItems[0] || null,
                                    error: currentItems[0] ? null : { message: 'Not found' },
                                })),
                                then: (resolve) => resolve({ data: currentItems, error: null }),
                            };
                            return chain;
                        };
                        return createFilter(table);
                    }),
                    update: jest.fn().mockImplementation((updates) => {
                        const createUpdateFilter = (conditions) => {
                            const chain = {
                                eq: jest.fn().mockImplementation((field, val) => {
                                    conditions[field] = val;
                                    for (const row of table) {
                                        let matches = true;
                                        for (const [k, v] of Object.entries(conditions)) {
                                            if (row[k] !== v)
                                                matches = false;
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
                                        const found = table.find((row) => {
                                            for (const [k, v] of Object.entries(conditions)) {
                                                if (row[k] !== v)
                                                    return false;
                                            }
                                            return true;
                                        });
                                        return { data: found || null, error: null };
                                    }),
                                }),
                                then: (resolve) => resolve({ data: table, error: null }),
                            };
                            return chain;
                        };
                        return createUpdateFilter({});
                    }),
                    delete: jest.fn().mockImplementation(() => {
                        return {
                            eq: jest.fn().mockImplementation((field, val) => {
                                const idx = table.findIndex((row) => row[field] === val);
                                if (idx !== -1)
                                    table.splice(idx, 1);
                                return {
                                    then: (resolve) => resolve({ data: null, error: null }),
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
        const module = await testing_1.Test.createTestingModule({
            imports: [
                config_1.ConfigModule.forRoot({
                    isGlobal: true,
                    load: [() => ({ port: 3000, apiPrefix: 'api/v1' })],
                }),
            ],
            providers: [
                auth_service_1.AuthService,
                accounts_service_1.AccountsService,
                categories_service_1.CategoriesService,
                transactions_service_1.TransactionsService,
                budgets_service_1.BudgetsService,
                goals_service_1.GoalsService,
                analytics_service_1.AnalyticsService,
                ai_service_1.AiService,
                ai_tools_service_1.AiToolsService,
                { provide: supabase_service_1.SupabaseService, useValue: mockSupabaseService },
            ],
        }).compile();
        authService = module.get(auth_service_1.AuthService);
        accountsService = module.get(accounts_service_1.AccountsService);
        categoriesService = module.get(categories_service_1.CategoriesService);
        transactionsService = module.get(transactions_service_1.TransactionsService);
        budgetsService = module.get(budgets_service_1.BudgetsService);
        goalsService = module.get(goals_service_1.GoalsService);
        analyticsService = module.get(analytics_service_1.AnalyticsService);
        aiService = module.get(ai_service_1.AiService);
    });
    const userId = 'usr-e2e';
    let bankAccountId;
    let cashAccountId;
    let creditCardAccountId;
    let foodCategoryId;
    let emergencyGoalId;
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
            accountType: create_account_dto_1.AccountType.BANK,
            currency: 'INR',
            initialBalance: 100000,
        });
        bankAccountId = bank.id;
        expect(bank.currentBalance).toBe(100000);
        const cash = await accountsService.createAccount(userId, {
            name: 'Physical Cash Wallet',
            accountType: create_account_dto_1.AccountType.CASH,
            currency: 'INR',
            initialBalance: 5000,
        });
        cashAccountId = cash.id;
        expect(cash.currentBalance).toBe(5000);
        const card = await accountsService.createAccount(userId, {
            name: 'ICICI Amazon Pay Credit Card',
            accountType: create_account_dto_1.AccountType.CREDIT_CARD,
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
            type: create_transaction_dto_1.TransactionType.EXPENSE,
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
            type: create_transaction_dto_1.TransactionType.TRANSFER,
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
        expect(affordResponse.structuredInsight?.type).toBe(ai_entity_1.AiInsightType.AFFORDABILITY_CHECK);
        expect(affordResponse.structuredInsight?.affordability?.status).toBe(ai_entity_1.AffordabilityStatus.COMFORTABLE);
        const burnResponse = await aiService.processChat(userId, {
            message: 'How is my spending pacing and burn rate this month?',
        });
        expect(burnResponse.toolsUsed).toContain('get_monthly_burn_rate');
        expect(burnResponse.structuredInsight?.type).toBe(ai_entity_1.AiInsightType.BURN_RATE_CHECK);
        const goalResponse = await aiService.processChat(userId, {
            message: 'How is my savings pace for my Emergency Fund?',
        });
        expect(goalResponse.toolsUsed).toContain('get_savings_goals_pace');
        expect(goalResponse.structuredInsight?.type).toBe(ai_entity_1.AiInsightType.SAVINGS_GOALS_PACE);
        expect(goalResponse.structuredInsight?.savingsGoals?.totalSaved).toBe(20000);
    });
});
//# sourceMappingURL=e2e-lifecycle.spec.js.map