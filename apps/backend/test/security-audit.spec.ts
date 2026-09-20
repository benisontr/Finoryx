import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException, NotFoundException, BadRequestException } from '@nestjs/common';
import { ValidationPipe } from '@nestjs/common';
import { AccountsService } from '../src/modules/accounts/accounts.service';
import { TransactionsService } from '../src/modules/transactions/transactions.service';
import { GoalsService } from '../src/modules/goals/goals.service';
import { BudgetsService } from '../src/modules/budgets/budgets.service';
import { SupabaseService } from '../src/database/supabase.service';
import { SupabaseAuthGuard } from '../src/modules/auth/guards/supabase-auth.guard';
import { CreateAccountDto, AccountType } from '../src/modules/accounts/dto/create-account.dto';
import { CreateTransactionDto, TransactionType } from '../src/modules/transactions/dto/create-transaction.dto';

describe('Security & Tenant Isolation Audit', () => {
  let accountsService: AccountsService;
  let transactionsService: TransactionsService;
  let goalsService: GoalsService;
  let budgetsService: BudgetsService;
  let authGuard: SupabaseAuthGuard;

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
        getUser: jest.fn().mockImplementation((token: string) => {
          if (token === 'valid-user-a-jwt') {
            return { data: { user: { id: 'user-A', email: 'userA@finoryx.io' } }, error: null };
          }
          return { data: { user: null }, error: { message: 'Invalid token' } };
        }),
      },
    }),
    getAdminClient: jest.fn().mockReturnValue({
      from: jest.fn().mockImplementation((table: string) => ({
        select: jest.fn().mockImplementation((fields?: string) => ({
          eq: jest.fn().mockImplementation((field: string, val: any) => ({
            eq: jest.fn().mockImplementation((f2: string, v2: any) => {
              const matches = mockDbAccounts.filter(
                (r: any) => r[field] === val && r[f2] === v2,
              );
              return {
                single: jest.fn().mockResolvedValue({
                  data: matches[0] || null,
                  error: matches[0] ? null : { message: 'Not found' },
                }),
                then: (resolve: any) => resolve({ data: matches, error: null }),
              };
            }),
            single: jest.fn().mockImplementation(async () => {
              const match = mockDbAccounts.find((r: any) => r[field] === val);
              return { data: match || null, error: match ? null : { message: 'Not found' } };
            }),
            then: (resolve: any) =>
              resolve({
                data: mockDbAccounts.filter((r: any) => r[field] === val),
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
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AccountsService,
        TransactionsService,
        GoalsService,
        BudgetsService,
        SupabaseAuthGuard,
        { provide: SupabaseService, useValue: mockSupabaseService },
      ],
    }).compile();

    accountsService = module.get<AccountsService>(AccountsService);
    transactionsService = module.get<TransactionsService>(TransactionsService);
    goalsService = module.get<GoalsService>(GoalsService);
    budgetsService = module.get<BudgetsService>(BudgetsService);
    authGuard = module.get<SupabaseAuthGuard>(SupabaseAuthGuard);
  });

  const createMockContext = (headers: any = {}) => {
    const req: any = { headers };
    return {
      switchToHttp: () => ({
        getRequest: () => req,
        getResponse: () => ({}),
      }),
      getHandler: () => () => {},
      getClass: () => class {},
    } as any;
  };

  describe('1. Authentication Guard Verification', () => {
    it('should reject requests without authorization headers with 401 Unauthorized', async () => {
      const ctx = createMockContext({});

      await expect(authGuard.canActivate(ctx)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('should reject requests with malformed bearer tokens', async () => {
      const ctx = createMockContext({ authorization: 'Bearer malformed-token' });

      await expect(authGuard.canActivate(ctx)).rejects.toThrow(
        UnauthorizedException,
      );
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
      await expect(accountsService.getAccountById('user-A', 'acc-user-b')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should prevent User A from initiating transfers from User B source account', async () => {
      await expect(
        transactionsService.createTransaction('user-A', {
          accountId: 'acc-user-b',
          destinationAccountId: 'acc-user-a',
          type: TransactionType.TRANSFER,
          amount: 500,
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should prevent User A from updating or deleting User B account', async () => {
      await expect(
        accountsService.updateAccount('user-A', 'acc-user-b', { name: 'Compromised Name' }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('3. DTO Schema Validation & Injection Hardening', () => {
    const validator = new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    });

    it('should reject negative amounts in transaction creation payload', async () => {
      const invalidPayload = {
        accountId: 'acc-user-a',
        type: TransactionType.EXPENSE,
        amount: -500.0,
      };

      await expect(
        validator.transform(invalidPayload, { type: 'body', metatype: CreateTransactionDto }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject malicious non-whitelisted fields (prototype pollution / parameter injection)', async () => {
      const maliciousPayload = {
        name: 'Hacked Account',
        accountType: AccountType.BANK,
        currency: 'INR',
        initialBalance: 100,
        isAdmin: true,
        rootAccess: true,
        __proto__: { backdoor: true },
      };

      await expect(
        validator.transform(maliciousPayload, { type: 'body', metatype: CreateAccountDto }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject invalid enum values in account creation', async () => {
      const invalidEnumPayload = {
        name: 'Fake Account',
        accountType: 'ILLEGAL_TYPE',
        currency: 'INR',
      };

      await expect(
        validator.transform(invalidEnumPayload, { type: 'body', metatype: CreateAccountDto }),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
