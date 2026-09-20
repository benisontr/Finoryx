import { Test, TestingModule } from '@nestjs/testing';
import { TransactionsService } from './transactions.service';
import { SupabaseService } from '../../database/supabase.service';
import { TransactionType } from './dto/create-transaction.dto';

describe('TransactionsService', () => {
  let service: TransactionsService;
  let mockSupabaseService: Partial<SupabaseService>;

  let mockSourceAccount: any;
  let mockDestAccount: any;

  beforeEach(async () => {
    mockSourceAccount = {
      id: 'acc-src',
      user_id: 'user-123',
      name: 'HDFC Bank',
      current_balance: '50000.00',
    };

    mockDestAccount = {
      id: 'acc-dest',
      user_id: 'user-123',
      name: 'Cash Wallet',
      current_balance: '2000.00',
    };

    mockSupabaseService = {
      getAdminClient: jest.fn().mockReturnValue({
        from: jest.fn().mockImplementation((tableName: string) => {
          if (tableName === 'accounts') {
            return {
              select: jest.fn().mockReturnValue({
                eq: jest.fn().mockImplementation((field: string, val: any) => {
                  return {
                    eq: jest.fn().mockReturnValue({
                      single: jest.fn().mockImplementation(() => {
                        if (val === 'acc-src') return Promise.resolve({ data: mockSourceAccount, error: null });
                        if (val === 'acc-dest') return Promise.resolve({ data: mockDestAccount, error: null });
                        return Promise.resolve({ data: null, error: { message: 'Not found' } });
                      }),
                    }),
                    single: jest.fn().mockImplementation(() => {
                      if (val === 'acc-src') return Promise.resolve({ data: mockSourceAccount, error: null });
                      if (val === 'acc-dest') return Promise.resolve({ data: mockDestAccount, error: null });
                      return Promise.resolve({ data: null, error: { message: 'Not found' } });
                    }),
                  };
                }),
              }),
              update: jest.fn().mockImplementation((updateData: any) => {
                return {
                  eq: jest.fn().mockImplementation((field: string, val: any) => {
                    if (val === 'acc-src') {
                      mockSourceAccount.current_balance = updateData.current_balance.toString();
                    }
                    if (val === 'acc-dest') {
                      mockDestAccount.current_balance = updateData.current_balance.toString();
                    }
                    return Promise.resolve({ error: null });
                  }),
                };
              }),
            };
          }

          if (tableName === 'transactions') {
            const txRecord = {
              id: 'tx-1',
              user_id: 'user-123',
              account_id: 'acc-src',
              destination_account_id: 'acc-dest',
              category_id: null,
              type: 'transfer',
              amount: '5000.00',
              fee_amount: '0.00',
              transaction_date: '2026-09-19T10:00:00.000Z',
              description: 'ATM Cash Withdrawal',
              tags: [],
              receipt_url: null,
              is_recurring: false,
              created_at: '2026-09-19T10:00:00.000Z',
              updated_at: '2026-09-19T10:00:00.000Z',
            };

            return {
              insert: jest.fn().mockReturnValue({
                select: jest.fn().mockReturnValue({
                  single: jest.fn().mockResolvedValue({
                    data: txRecord,
                    error: null,
                  }),
                }),
              }),
              select: jest.fn().mockReturnValue({
                eq: jest.fn().mockReturnValue({
                  eq: jest.fn().mockReturnValue({
                    single: jest.fn().mockResolvedValue({
                      data: txRecord,
                      error: null,
                    }),
                  }),
                  order: jest.fn().mockReturnValue({
                    range: jest.fn().mockResolvedValue({
                      data: [txRecord],
                      count: 1,
                      error: null,
                    }),
                  }),
                  single: jest.fn().mockResolvedValue({
                    data: txRecord,
                    error: null,
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
        }),
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TransactionsService,
        { provide: SupabaseService, useValue: mockSupabaseService },
      ],
    }).compile();

    service = module.get<TransactionsService>(TransactionsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should record double-entry transfer and update both balances atomically', async () => {
    // Initial: src = 50000, dest = 2000
    const tx = await service.createTransaction('user-123', {
      accountId: 'acc-src',
      destinationAccountId: 'acc-dest',
      type: TransactionType.TRANSFER,
      amount: 5000,
      feeAmount: 0,
      description: 'ATM Cash Withdrawal',
    });

    expect(tx).toBeDefined();
    expect(tx.amount).toBe(5000);
    // Verified atomic update: src should become 45000, dest should become 7000
    expect(mockSourceAccount.current_balance).toBe('45000');
    expect(mockDestAccount.current_balance).toBe('7000');
  });

  it('should delete a transfer transaction and revert both balances', async () => {
    mockSourceAccount.current_balance = '45000';
    mockDestAccount.current_balance = '7000';

    const result = await service.deleteTransaction('user-123', 'tx-1');
    expect(result.success).toBe(true);

    // After reversal: src reverts to 50000, dest reverts to 2000
    expect(mockSourceAccount.current_balance).toBe('50000');
    expect(mockDestAccount.current_balance).toBe('2000');
  });
});
