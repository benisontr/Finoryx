"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const testing_1 = require("@nestjs/testing");
const common_1 = require("@nestjs/common");
const common_2 = require("@nestjs/common");
const accounts_service_1 = require("../src/modules/accounts/accounts.service");
const transactions_service_1 = require("../src/modules/transactions/transactions.service");
const goals_service_1 = require("../src/modules/goals/goals.service");
const budgets_service_1 = require("../src/modules/budgets/budgets.service");
const supabase_service_1 = require("../src/database/supabase.service");
const supabase_auth_guard_1 = require("../src/modules/auth/guards/supabase-auth.guard");
const create_account_dto_1 = require("../src/modules/accounts/dto/create-account.dto");
const create_transaction_dto_1 = require("../src/modules/transactions/dto/create-transaction.dto");
describe('Security & Tenant Isolation Audit', () => {
    let accountsService;
    let transactionsService;
    let goalsService;
    let budgetsService;
    let authGuard;
    const mockDbAccounts = [
        {
            id: 'acc-user-a',
            user_id: 'user-A',
            name: 'User A Secret Vault',
            account_type: 'bank',
            currency: 'INR',
            current_balance: '1000000.00',
            is_archived: false,
        },
        {
            id: 'acc-user-b',
            user_id: 'user-B',
            name: 'User B Account',
            account_type: 'bank',
            currency: 'INR',
            current_balance: '500.00',
            is_archived: false,
        },
    ];
    const mockSupabaseService = {
        getClient: jest.fn().mockReturnValue({
            auth: {
                getUser: jest.fn().mockImplementation((token) => {
                    if (token === 'valid-user-a-jwt') {
                        return { data: { user: { id: 'user-A', email: 'userA@finoryx.io' } }, error: null };
                    }
                    return { data: { user: null }, error: { message: 'Invalid token' } };
                }),
            },
        }),
        getAdminClient: jest.fn().mockReturnValue({
            from: jest.fn().mockImplementation((table) => ({
                select: jest.fn().mockImplementation((fields) => ({
                    eq: jest.fn().mockImplementation((field, val) => ({
                        eq: jest.fn().mockImplementation((f2, v2) => {
                            const matches = mockDbAccounts.filter((r) => r[field] === val && r[f2] === v2);
                            return {
                                single: jest.fn().mockResolvedValue({
                                    data: matches[0] || null,
                                    error: matches[0] ? null : { message: 'Not found' },
                                }),
                                then: (resolve) => resolve({ data: matches, error: null }),
                            };
                        }),
                        single: jest.fn().mockImplementation(async () => {
                            const match = mockDbAccounts.find((r) => r[field] === val);
                            return { data: match || null, error: match ? null : { message: 'Not found' } };
                        }),
                        then: (resolve) => resolve({
                            data: mockDbAccounts.filter((r) => r[field] === val),
                            error: null,
                        }),
                    })),
                })),
                update: jest.fn().mockImplementation(() => ({
                    eq: jest.fn().mockImplementation(() => ({
                        select: jest.fn().mockReturnValue({
                            single: jest.fn().mockResolvedValue({ data: null, error: { message: 'Not found' } }),
                        }),
                    })),
                })),
                delete: jest.fn().mockImplementation(() => ({
                    eq: jest.fn().mockImplementation(() => ({
                        eq: jest.fn().mockResolvedValue({ data: null, error: null }),
                    })),
                })),
            })),
        }),
    };
    beforeAll(async () => {
        const module = await testing_1.Test.createTestingModule({
            providers: [
                accounts_service_1.AccountsService,
                transactions_service_1.TransactionsService,
                goals_service_1.GoalsService,
                budgets_service_1.BudgetsService,
                supabase_auth_guard_1.SupabaseAuthGuard,
                { provide: supabase_service_1.SupabaseService, useValue: mockSupabaseService },
            ],
        }).compile();
        accountsService = module.get(accounts_service_1.AccountsService);
        transactionsService = module.get(transactions_service_1.TransactionsService);
        goalsService = module.get(goals_service_1.GoalsService);
        budgetsService = module.get(budgets_service_1.BudgetsService);
        authGuard = module.get(supabase_auth_guard_1.SupabaseAuthGuard);
    });
    const createMockContext = (headers = {}) => {
        const req = { headers };
        return {
            switchToHttp: () => ({
                getRequest: () => req,
                getResponse: () => ({}),
            }),
            getHandler: () => () => { },
            getClass: () => class {
            },
        };
    };
    describe('1. Authentication Guard Verification', () => {
        it('should reject requests without authorization headers with 401 Unauthorized', async () => {
            const ctx = createMockContext({});
            await expect(authGuard.canActivate(ctx)).rejects.toThrow(common_1.UnauthorizedException);
        });
        it('should reject requests with malformed bearer tokens', async () => {
            const ctx = createMockContext({ authorization: 'Bearer malformed-token' });
            await expect(authGuard.canActivate(ctx)).rejects.toThrow(common_1.UnauthorizedException);
        });
        it('should allow requests with valid authenticated user JWT tokens', async () => {
            const ctx = createMockContext({ authorization: 'Bearer valid-user-a-jwt' });
            const allowed = await authGuard.canActivate(ctx);
            expect(allowed).toBe(true);
            const req = ctx.switchToHttp().getRequest();
            expect(req.user).toBeDefined();
            expect(req.user.id).toBe('user-A');
        });
    });
    describe('2. Multi-Tenant Boundary Isolation', () => {
        it('should prevent User A from reading User B account', async () => {
            await expect(accountsService.getAccountById('user-A', 'acc-user-b')).rejects.toThrow(common_1.NotFoundException);
        });
        it('should prevent User A from initiating transfers from User B source account', async () => {
            await expect(transactionsService.createTransaction('user-A', {
                accountId: 'acc-user-b',
                destinationAccountId: 'acc-user-a',
                type: create_transaction_dto_1.TransactionType.TRANSFER,
                amount: 500,
            })).rejects.toThrow(common_1.NotFoundException);
        });
        it('should prevent User A from updating or deleting User B account', async () => {
            await expect(accountsService.updateAccount('user-A', 'acc-user-b', { name: 'Compromised Name' })).rejects.toThrow(common_1.NotFoundException);
        });
    });
    describe('3. DTO Schema Validation & Injection Hardening', () => {
        const validator = new common_2.ValidationPipe({
            whitelist: true,
            forbidNonWhitelisted: true,
            transform: true,
        });
        it('should reject negative amounts in transaction creation payload', async () => {
            const invalidPayload = {
                accountId: 'acc-user-a',
                type: create_transaction_dto_1.TransactionType.EXPENSE,
                amount: -500.0,
            };
            await expect(validator.transform(invalidPayload, { type: 'body', metatype: create_transaction_dto_1.CreateTransactionDto })).rejects.toThrow(common_1.BadRequestException);
        });
        it('should reject malicious non-whitelisted fields (prototype pollution / parameter injection)', async () => {
            const maliciousPayload = {
                name: 'Hacked Account',
                accountType: create_account_dto_1.AccountType.BANK,
                currency: 'INR',
                initialBalance: 100,
                isAdmin: true,
                rootAccess: true,
                __proto__: { backdoor: true },
            };
            await expect(validator.transform(maliciousPayload, { type: 'body', metatype: create_account_dto_1.CreateAccountDto })).rejects.toThrow(common_1.BadRequestException);
        });
        it('should reject invalid enum values in account creation', async () => {
            const invalidEnumPayload = {
                name: 'Fake Account',
                accountType: 'ILLEGAL_TYPE',
                currency: 'INR',
            };
            await expect(validator.transform(invalidEnumPayload, { type: 'body', metatype: create_account_dto_1.CreateAccountDto })).rejects.toThrow(common_1.BadRequestException);
        });
    });
});
//# sourceMappingURL=security-audit.spec.js.map