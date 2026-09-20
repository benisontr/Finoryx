import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { SupabaseService } from '../../database/supabase.service';
import { CreateTransactionDto, TransactionType } from './dto/create-transaction.dto';
import { QueryTransactionsDto } from './dto/query-transactions.dto';
import { TransactionEntity } from './entities/transaction.entity';
import { PaginationMetaDto } from '../../common/dto/api-response.dto';

@Injectable()
export class TransactionsService {
  private readonly logger = new Logger(TransactionsService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  async createTransaction(userId: string, dto: CreateTransactionDto): Promise<TransactionEntity> {
    const supabase = this.supabaseService.getAdminClient();

    const fee = dto.feeAmount || 0.0;
    const amount = dto.amount;

    if (dto.type === TransactionType.TRANSFER) {
      if (!dto.destinationAccountId) {
        throw new BadRequestException('Transfer transactions require a destinationAccountId');
      }
      if (dto.destinationAccountId === dto.accountId) {
        throw new BadRequestException('Source and destination accounts cannot be identical');
      }
    }

    // 1. Fetch Source Account
    const { data: sourceAccount, error: srcError } = await supabase
      .from('accounts')
      .select('*')
      .eq('id', dto.accountId)
      .eq('user_id', userId)
      .single();

    if (srcError || !sourceAccount) {
      throw new NotFoundException(`Source account '${dto.accountId}' not found`);
    }

    let destinationAccount: any = null;
    if (dto.type === TransactionType.TRANSFER && dto.destinationAccountId) {
      const { data: destAccount, error: destError } = await supabase
        .from('accounts')
        .select('*')
        .eq('id', dto.destinationAccountId)
        .eq('user_id', userId)
        .single();

      if (destError || !destAccount) {
        throw new NotFoundException(`Destination account '${dto.destinationAccountId}' not found`);
      }
      destinationAccount = destAccount;
    }

    // 2. Insert Transaction Record
    const { data: transactionData, error: txError } = await supabase
      .from('transactions')
      .insert({
        user_id: userId,
        account_id: dto.accountId,
        destination_account_id: dto.destinationAccountId ?? null,
        category_id: dto.categoryId ?? null,
        type: dto.type,
        amount: amount,
        fee_amount: fee,
        transaction_date: dto.transactionDate || new Date().toISOString(),
        description: dto.description ?? null,
        tags: dto.tags ?? [],
        receipt_url: dto.receiptUrl ?? null,
        is_recurring: dto.isRecurring ?? false,
      })
      .select(`
        *,
        accounts:account_id ( name ),
        destination_account:destination_account_id ( name ),
        categories:category_id ( name, icon, color_hex )
      `)
      .single();

    if (txError) {
      this.logger.error(`Failed to record transaction: ${txError.message}`);
      throw new InternalServerErrorException(txError.message);
    }

    // 3. Atomically Update Account Balances
    const srcCurrentBal = parseFloat(sourceAccount.current_balance) || 0.0;

    if (dto.type === TransactionType.EXPENSE) {
      const newBalance = srcCurrentBal - (amount + fee);
      await supabase
        .from('accounts')
        .update({ current_balance: newBalance })
        .eq('id', dto.accountId);
    } else if (dto.type === TransactionType.INCOME) {
      const newBalance = srcCurrentBal + amount - fee;
      await supabase
        .from('accounts')
        .update({ current_balance: newBalance })
        .eq('id', dto.accountId);
    } else if (dto.type === TransactionType.TRANSFER && destinationAccount) {
      const destCurrentBal = parseFloat(destinationAccount.current_balance) || 0.0;
      const newSrcBalance = srcCurrentBal - (amount + fee);
      const newDestBalance = destCurrentBal + amount;

      await supabase
        .from('accounts')
        .update({ current_balance: newSrcBalance })
        .eq('id', dto.accountId);

      await supabase
        .from('accounts')
        .update({ current_balance: newDestBalance })
        .eq('id', dto.destinationAccountId);
    }

    return TransactionEntity.fromRow(transactionData);
  }

  async getTransactions(
    userId: string,
    queryDto: QueryTransactionsDto,
  ): Promise<{ data: TransactionEntity[]; meta: PaginationMetaDto }> {
    const supabase = this.supabaseService.getAdminClient();

    const page = queryDto.page || 1;
    const limit = queryDto.limit || 20;
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    let query = supabase
      .from('transactions')
      .select(
        `
        *,
        accounts:account_id ( name ),
        destination_account:destination_account_id ( name ),
        categories:category_id ( name, icon, color_hex )
      `,
        { count: 'exact' },
      )
      .eq('user_id', userId);

    if (queryDto.accountId) {
      query = query.or(
        `account_id.eq.${queryDto.accountId},destination_account_id.eq.${queryDto.accountId}`,
      );
    }

    if (queryDto.categoryId) {
      query = query.eq('category_id', queryDto.categoryId);
    }

    if (queryDto.type) {
      query = query.eq('type', queryDto.type);
    }

    if (queryDto.startDate) {
      query = query.gte('transaction_date', queryDto.startDate);
    }

    if (queryDto.endDate) {
      query = query.lte('transaction_date', queryDto.endDate);
    }

    if (queryDto.search) {
      query = query.ilike('description', `%${queryDto.search}%`);
    }

    const sortBy = queryDto.sortBy || 'transaction_date';
    const ascending = queryDto.sortOrder === 'ASC';

    query = query.order(sortBy, { ascending }).range(from, to);

    const { data, count, error } = await query;

    if (error) {
      this.logger.error(`Error querying transactions: ${error.message}`);
      throw new InternalServerErrorException(error.message);
    }

    const totalItems = count || 0;
    const totalPages = Math.ceil(totalItems / limit);

    return {
      data: (data || []).map(TransactionEntity.fromRow),
      meta: {
        page,
        limit,
        totalItems,
        totalPages,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1,
      },
    };
  }

  async getTransactionById(userId: string, transactionId: string): Promise<TransactionEntity> {
    const supabase = this.supabaseService.getAdminClient();

    const { data, error } = await supabase
      .from('transactions')
      .select(
        `
        *,
        accounts:account_id ( name ),
        destination_account:destination_account_id ( name ),
        categories:category_id ( name, icon, color_hex )
      `,
      )
      .eq('id', transactionId)
      .eq('user_id', userId)
      .single();

    if (error || !data) {
      throw new NotFoundException(`Transaction '${transactionId}' not found`);
    }

    return TransactionEntity.fromRow(data);
  }

  async deleteTransaction(
    userId: string,
    transactionId: string,
  ): Promise<{ success: boolean; message: string }> {
    const transaction = await this.getTransactionById(userId, transactionId);

    const supabase = this.supabaseService.getAdminClient();
    const amount = transaction.amount;
    const fee = transaction.feeAmount;

    // 1. Revert Source Account Balance
    const { data: srcAccount } = await supabase
      .from('accounts')
      .select('current_balance')
      .eq('id', transaction.accountId)
      .single();

    if (srcAccount) {
      const srcCurrentBal = parseFloat(srcAccount.current_balance) || 0.0;
      let revertedSrcBal = srcCurrentBal;

      if (transaction.type === TransactionType.EXPENSE) {
        revertedSrcBal = srcCurrentBal + (amount + fee);
      } else if (transaction.type === TransactionType.INCOME) {
        revertedSrcBal = srcCurrentBal - (amount - fee);
      } else if (transaction.type === TransactionType.TRANSFER) {
        revertedSrcBal = srcCurrentBal + (amount + fee);

        if (transaction.destinationAccountId) {
          const { data: destAccount } = await supabase
            .from('accounts')
            .select('current_balance')
            .eq('id', transaction.destinationAccountId)
            .single();

          if (destAccount) {
            const destCurrentBal = parseFloat(destAccount.current_balance) || 0.0;
            await supabase
              .from('accounts')
              .update({ current_balance: destCurrentBal - amount })
              .eq('id', transaction.destinationAccountId);
          }
        }
      }

      await supabase
        .from('accounts')
        .update({ current_balance: revertedSrcBal })
        .eq('id', transaction.accountId);
    }

    // 2. Delete the transaction record
    const { error: deleteError } = await supabase
      .from('transactions')
      .delete()
      .eq('id', transactionId)
      .eq('user_id', userId);

    if (deleteError) {
      this.logger.error(`Failed to delete transaction ${transactionId}: ${deleteError.message}`);
      throw new InternalServerErrorException(deleteError.message);
    }

    return {
      success: true,
      message: 'Transaction successfully deleted and balances reverted.',
    };
  }
}
