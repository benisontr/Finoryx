"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const testing_1 = require("@nestjs/testing");
const common_1 = require("@nestjs/common");
const transactions_service_1 = require("../src/modules/transactions/transactions.service");
const goals_service_1 = require("../src/modules/goals/goals.service");
const budgets_service_1 = require("../src/modules/budgets/budgets.service");
const ai_tools_service_1 = require("../src/modules/ai/ai-tools.service");
const analytics_service_1 = require("../src/modules/analytics/analytics.service");
const supabase_service_1 = require("../src/database/supabase.service");
const create_transaction_dto_1 = require("../src/modules/transactions/dto/create-transaction.dto");
const ai_entity_1 = require("../src/modules/ai/entities/ai.entity");
describe('Mathematical Invariants & Edge Case Validation', () => {
    let transactionsService;
    let goalsService;
    let budgetsService;
    let aiToolsService;
    const createMockChain = (data = null, error = null) => {
        const chain = {
            select: jest.fn().mockImplementation(() => chain),
            eq: jest.fn().mockImplementation(() => chain),
            gte: jest.fn().mockImplementation(() => chain),
            lte: jest.fn().mockImplementation(() => chain),
            order: jest.fn().mockImplementation(() => chain),
            limit: jest.fn().mockImplementation(() => chain),
            single: jest.fn().mockResolvedValue({ data, error }),
            then: (resolve) => resolve({ data: Array.isArray(data) ? data : (data ? [data] : []), error }),
        };
        return chain;
    };
    const mockSupabase = {
        from: jest.fn().mockImplementation((tableName) => {
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
        const module = await testing_1.Test.createTestingModule({
            providers: [
                transactions_service_1.TransactionsService,
                goals_service_1.GoalsService,
                budgets_service_1.BudgetsService,
                ai_tools_service_1.AiToolsService,
                { provide: supabase_service_1.SupabaseService, useValue: { getAdminClient: () => mockSupabase, getClient: () => mockSupabase } },
                { provide: analytics_service_1.AnalyticsService, useValue: mockAnalytics },
            ],
        }).compile();
        transactionsService = module.get(transactions_service_1.TransactionsService);
        goalsService = module.get(goals_service_1.GoalsService);
        budgetsService = module.get(budgets_service_1.BudgetsService);
        aiToolsService = module.get(ai_tools_service_1.AiToolsService);
    });
    describe('1. Double-Entry Transfer Invariants', () => {
        it('should reject transfers where source and destination account are identical', async () => {
            await expect(transactionsService.createTransaction('user-1', {
                accountId: 'acc-same',
                destinationAccountId: 'acc-same',
                type: create_transaction_dto_1.TransactionType.TRANSFER,
                amount: 500,
            })).rejects.toThrow(common_1.BadRequestException);
        });
        it('should reject transfer missing destination account', async () => {
            await expect(transactionsService.createTransaction('user-1', {
                accountId: 'acc-1',
                type: create_transaction_dto_1.TransactionType.TRANSFER,
                amount: 500,
            })).rejects.toThrow(common_1.BadRequestException);
        });
    });
    describe('2. Savings Goals Timeline & Account Linking Invariants', () => {
        it('should reject goal creation when linked account does not belong to user', async () => {
            mockSupabase.from.mockReturnValueOnce(createMockChain(null, { message: 'Not found' }));
            await expect(goalsService.create('user-1', {
                name: 'Invalid Goal',
                targetAmount: 50000,
                targetDate: new Date(Date.now() + 1000000).toISOString(),
                linkedAccountId: 'acc-nonexistent',
            })).rejects.toThrow(common_1.BadRequestException);
        });
    });
    describe('3. AI Affordability Engine with Zero Reserves', () => {
        it('should mark purchase as UNRECOMMENDED when user holds ₹0 liquid cash', async () => {
            mockSupabase.from.mockImplementationOnce(() => createMockChain({ id: 'acc-1', user_id: 'user-1', current_balance: '0.00', account_type: 'bank' }));
            const result = await aiToolsService.checkAffordability('user-1', 1500);
            expect(result.status).toBe(ai_entity_1.AffordabilityStatus.UNRECOMMENDED);
            expect(result.currentLiquidBuffer).toBe(0);
            expect(result.budgetImpactMessage).toContain('exceeds available liquid cash');
        });
    });
});
//# sourceMappingURL=edge-cases.spec.js.map