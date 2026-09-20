import { TransactionType } from '../dto/create-transaction.dto';

export class TransactionEntity {
  id: string;
  userId: string;
  accountId: string;
  destinationAccountId?: string | null;
  categoryId?: string | null;
  type: TransactionType;
  amount: number;
  feeAmount: number;
  transactionDate: string;
  description?: string | null;
  tags: string[];
  receiptUrl?: string | null;
  isRecurring: boolean;
  createdAt: string;
  updatedAt: string;

  // Joined metadata for fast client display
  accountName?: string;
  destinationAccountName?: string;
  categoryName?: string;
  categoryIcon?: string;
  categoryColorHex?: string;

  static fromRow(row: any): TransactionEntity {
    return {
      id: row.id,
      userId: row.user_id,
      accountId: row.account_id,
      destinationAccountId: row.destination_account_id,
      categoryId: row.category_id,
      type: row.type as TransactionType,
      amount: parseFloat(row.amount) || 0.0,
      feeAmount: parseFloat(row.fee_amount) || 0.0,
      transactionDate: row.transaction_date,
      description: row.description,
      tags: row.tags || [],
      receiptUrl: row.receipt_url,
      isRecurring: row.is_recurring,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      accountName: row.accounts?.name,
      destinationAccountName: row.destination_account?.name,
      categoryName: row.categories?.name,
      categoryIcon: row.categories?.icon,
      categoryColorHex: row.categories?.color_hex,
    };
  }
}
