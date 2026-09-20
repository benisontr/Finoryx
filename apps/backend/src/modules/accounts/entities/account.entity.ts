import { AccountType } from '../dto/create-account.dto';

export class AccountEntity {
  id: string;
  userId: string;
  name: string;
  accountType: AccountType;
  currency: string;
  currentBalance: number;
  creditLimit?: number | null;
  billingCycleDay?: number | null;
  isArchived: boolean;
  createdAt: string;
  updatedAt: string;

  static fromRow(row: any): AccountEntity {
    return {
      id: row.id,
      userId: row.user_id,
      name: row.name,
      accountType: row.account_type as AccountType,
      currency: row.currency,
      currentBalance: parseFloat(row.current_balance) || 0.0,
      creditLimit: row.credit_limit !== null ? parseFloat(row.credit_limit) : null,
      billingCycleDay: row.billing_cycle_day,
      isArchived: row.is_archived,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}

export interface AccountsSummary {
  totalNetWorth: number;
  totalAssets: number;
  totalLiabilities: number;
  accountCount: number;
  accountsByType: Record<string, number>;
}
