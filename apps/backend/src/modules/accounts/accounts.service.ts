import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { SupabaseService } from '../../database/supabase.service';
import { CreateAccountDto, UpdateAccountDto, AccountType } from './dto/create-account.dto';
import { AccountEntity, AccountsSummary } from './entities/account.entity';

@Injectable()
export class AccountsService {
  private readonly logger = new Logger(AccountsService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  async getAccounts(userId: string, includeArchived = false): Promise<AccountEntity[]> {
    const supabase = this.supabaseService.getAdminClient();

    let query = supabase
      .from('accounts')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: true });

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    const { data, error } = await query;

    if (error) {
      this.logger.error(`Failed to get accounts for user ${userId}: ${error.message}`);
      throw new InternalServerErrorException(error.message);
    }

    return (data || []).map(AccountEntity.fromRow);
  }

  async getAccountById(userId: string, accountId: string): Promise<AccountEntity> {
    const supabase = this.supabaseService.getAdminClient();

    const { data, error } = await supabase
      .from('accounts')
      .select('*')
      .eq('id', accountId)
      .eq('user_id', userId)
      .single();

    if (error || !data) {
      throw new NotFoundException(`Account with ID '${accountId}' not found`);
    }

    return AccountEntity.fromRow(data);
  }

  async createAccount(userId: string, dto: CreateAccountDto): Promise<AccountEntity> {
    const supabase = this.supabaseService.getAdminClient();

    const initialBalance = dto.initialBalance !== undefined ? dto.initialBalance : 0.0;

    const { data, error } = await supabase
      .from('accounts')
      .insert({
        user_id: userId,
        name: dto.name,
        account_type: dto.accountType,
        currency: dto.currency || 'INR',
        current_balance: initialBalance,
        credit_limit: dto.creditLimit ?? null,
        billing_cycle_day: dto.billingCycleDay ?? null,
        is_archived: false,
      })
      .select('*')
      .single();

    if (error) {
      this.logger.error(`Failed to create account for user ${userId}: ${error.message}`);
      throw new BadRequestException(error.message);
    }

    return AccountEntity.fromRow(data);
  }

  async updateAccount(
    userId: string,
    accountId: string,
    dto: UpdateAccountDto,
  ): Promise<AccountEntity> {
    const supabase = this.supabaseService.getAdminClient();

    // Verify ownership
    await this.getAccountById(userId, accountId);

    const updates: Record<string, any> = {};
    if (dto.name !== undefined) updates.name = dto.name;
    if (dto.accountType !== undefined) updates.account_type = dto.accountType;
    if (dto.creditLimit !== undefined) updates.credit_limit = dto.creditLimit;
    if (dto.billingCycleDay !== undefined) updates.billing_cycle_day = dto.billingCycleDay;
    if (dto.isArchived !== undefined) updates.is_archived = dto.isArchived;

    const { data, error } = await supabase
      .from('accounts')
      .update(updates)
      .eq('id', accountId)
      .eq('user_id', userId)
      .select('*')
      .single();

    if (error) {
      this.logger.error(`Failed to update account ${accountId}: ${error.message}`);
      throw new InternalServerErrorException(error.message);
    }

    return AccountEntity.fromRow(data);
  }

  async deleteAccount(userId: string, accountId: string): Promise<{ success: boolean; message: string }> {
    const supabase = this.supabaseService.getAdminClient();

    // Check if account has any associated transactions
    const { count, error: countError } = await supabase
      .from('transactions')
      .select('*', { count: 'exact', head: true })
      .or(`account_id.eq.${accountId},destination_account_id.eq.${accountId}`);

    if (countError) {
      throw new InternalServerErrorException(countError.message);
    }

    if (count && count > 0) {
      // Soft-archive if transactions exist to preserve ledger integrity
      await this.updateAccount(userId, accountId, { isArchived: true });
      return {
        success: true,
        message: 'Account contains transactions and was archived to preserve financial history.',
      };
    }

    // Hard delete if clean
    const { error } = await supabase
      .from('accounts')
      .delete()
      .eq('id', accountId)
      .eq('user_id', userId);

    if (error) {
      this.logger.error(`Failed to delete account ${accountId}: ${error.message}`);
      throw new InternalServerErrorException(error.message);
    }

    return {
      success: true,
      message: 'Account successfully deleted.',
    };
  }

  async getAccountsSummary(userId: string): Promise<AccountsSummary> {
    const accounts = await this.getAccounts(userId, false);

    let totalAssets = 0;
    let totalLiabilities = 0;
    const accountsByType: Record<string, number> = {};

    for (const acc of accounts) {
      accountsByType[acc.accountType] = (accountsByType[acc.accountType] || 0) + acc.currentBalance;

      if (acc.accountType === AccountType.CREDIT_CARD) {
        // For credit cards, a positive balance is treated as owed (liability)
        if (acc.currentBalance > 0) {
          totalLiabilities += acc.currentBalance;
        } else {
          totalAssets += Math.abs(acc.currentBalance);
        }
      } else {
        if (acc.currentBalance >= 0) {
          totalAssets += acc.currentBalance;
        } else {
          totalLiabilities += Math.abs(acc.currentBalance);
        }
      }
    }

    const totalNetWorth = totalAssets - totalLiabilities;

    return {
      totalNetWorth,
      totalAssets,
      totalLiabilities,
      accountCount: accounts.length,
      accountsByType,
    };
  }
}
