import { Test, TestingModule } from '@nestjs/testing';
import { AccountsService } from './accounts.service';
import { SupabaseService } from '../../database/supabase.service';
import { AccountType } from './dto/create-account.dto';

describe('AccountsService', () => {
  let service: AccountsService;
  let mockSupabaseService: Partial<SupabaseService>;

  const mockAccountRows = [
    {
      id: 'acc-1',
      user_id: 'user-123',
      name: 'HDFC Salary Bank',
      account_type: 'bank',
      currency: 'INR',
      current_balance: '50000.00',
      credit_limit: null,
      billing_cycle_day: null,
      is_archived: false,
      created_at: '2026-09-18T20:00:00.000Z',
      updated_at: '2026-09-18T20:00:00.000Z',
    },
    {
      id: 'acc-2',
      user_id: 'user-123',
      name: 'ICICI Amazon Pay Card',
      account_type: 'credit_card',
      currency: 'INR',
      current_balance: '12000.00',
      credit_limit: '100000.00',
      billing_cycle_day: 15,
      is_archived: false,
      created_at: '2026-09-18T20:00:00.000Z',
      updated_at: '2026-09-18T20:00:00.000Z',
    },
  ];

  beforeEach(async () => {
    mockSupabaseService = {
      getAdminClient: jest.fn().mockReturnValue({
        from: jest.fn().mockImplementation((tableName: string) => {
          if (tableName === 'accounts') {
            return {
              select: jest.fn().mockReturnValue({
                eq: jest.fn().mockImplementation((field: string, val: any) => {
                  if (field === 'id') {
                    const row = mockAccountRows.find((r) => r.id === val);
                    return {
                      eq: jest.fn().mockReturnValue({
                        single: jest.fn().mockResolvedValue({
                          data: row || null,
                          error: row ? null : { message: 'Not found' },
                        }),
                      }),
                    };
                  }
                  return {
                    order: jest.fn().mockReturnValue({
                      eq: jest.fn().mockResolvedValue({
                        data: mockAccountRows,
                        error: null,
                      }),
                    }),
                    eq: jest.fn().mockResolvedValue({
                      data: mockAccountRows,
                      error: null,
                    }),
                  };
                }),
              }),
              insert: jest.fn().mockReturnValue({
                select: jest.fn().mockReturnValue({
                  single: jest.fn().mockResolvedValue({
                    data: mockAccountRows[0],
                    error: null,
                  }),
                }),
              }),
              update: jest.fn().mockReturnValue({
                eq: jest.fn().mockReturnValue({
                  eq: jest.fn().mockReturnValue({
                    select: jest.fn().mockReturnValue({
                      single: jest.fn().mockResolvedValue({
                        data: { ...mockAccountRows[0], name: 'Updated HDFC' },
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
                or: jest.fn().mockResolvedValue({
                  count: 0,
                  error: null,
                }),
              }),
            };
          }
        }),
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AccountsService,
        { provide: SupabaseService, useValue: mockSupabaseService },
      ],
    }).compile();

    service = module.get<AccountsService>(AccountsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should get accounts and parse numeric current_balance properly', async () => {
    const accounts = await service.getAccounts('user-123', false);
    expect(accounts).toBeDefined();
    expect(accounts.length).toBe(2);
    expect(accounts[0].currentBalance).toBe(50000.0);
    expect(accounts[1].currentBalance).toBe(12000.0);
  });

  it('should get an account by ID', async () => {
    const account = await service.getAccountById('user-123', 'acc-1');
    expect(account).toBeDefined();
    expect(account.id).toBe('acc-1');
    expect(account.name).toBe('HDFC Salary Bank');
    expect(account.accountType).toBe(AccountType.BANK);
  });

  it('should create an account successfully', async () => {
    const account = await service.createAccount('user-123', {
      name: 'HDFC Salary Bank',
      accountType: AccountType.BANK,
      currency: 'INR',
      initialBalance: 50000,
    });

    expect(account).toBeDefined();
    expect(account.name).toBe('HDFC Salary Bank');
  });

  it('should calculate accounts summary and net worth accurately (Assets - Liabilities)', async () => {
    const summary = await service.getAccountsSummary('user-123');

    // Assets = 50000, Liabilities (Credit Card Owed) = 12000 => Net Worth = 38000
    expect(summary.totalAssets).toBe(50000);
    expect(summary.totalLiabilities).toBe(12000);
    expect(summary.totalNetWorth).toBe(38000);
    expect(summary.accountCount).toBe(2);
  });
});
