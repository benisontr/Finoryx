import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { SupabaseService } from '../../database/supabase.service';
import { CreateBudgetDto, UpdateBudgetDto } from './dto/create-budget.dto';
import { BudgetEntity } from './entities/budget.entity';

@Injectable()
export class BudgetsService {
  private readonly logger = new Logger(BudgetsService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  async getBudgets(userId: string, month: number, year: number): Promise<BudgetEntity[]> {
    const supabase = this.supabaseService.getAdminClient();

    // 1. Fetch budgets for user & month/year
    const { data: budgets, error: budgetError } = await supabase
      .from('budgets')
      .select('*, categories:category_id ( name, icon, color_hex )')
      .eq('user_id', userId)
      .eq('month', month)
      .eq('year', year);

    if (budgetError) {
      this.logger.error(`Error fetching budgets: ${budgetError.message}`);
      throw new InternalServerErrorException(budgetError.message);
    }

    if (!budgets || budgets.length === 0) {
      return [];
    }

    // 2. Compute date boundaries for month
    const startDate = new Date(Date.UTC(year, month - 1, 1, 0, 0, 0)).toISOString();
    const lastDayOfMonth = new Date(year, month, 0).getDate();
    const endDate = new Date(Date.UTC(year, month - 1, lastDayOfMonth, 23, 59, 59, 999)).toISOString();

    // 3. Fetch all expenses for this month to aggregate spend by category
    const { data: transactions, error: txError } = await supabase
      .from('transactions')
      .select('category_id, amount, fee_amount')
      .eq('user_id', userId)
      .eq('type', 'expense')
      .gte('transaction_date', startDate)
      .lte('transaction_date', endDate);

    if (txError) {
      this.logger.error(`Error aggregating category spend: ${txError.message}`);
    }

    const spendByCategory: Record<string, number> = {};
    for (const tx of transactions || []) {
      if (tx.category_id) {
        const totalCost = (parseFloat(tx.amount) || 0) + (parseFloat(tx.fee_amount) || 0);
        spendByCategory[tx.category_id] = (spendByCategory[tx.category_id] || 0) + totalCost;
      }
    }

    const now = new Date();
    const isCurrentMonth = now.getFullYear() === year && now.getMonth() + 1 === month;
    const currentDay = isCurrentMonth ? now.getDate() : lastDayOfMonth;

    return budgets.map((b) => {
      const spent = spendByCategory[b.category_id] || 0.0;
      return BudgetEntity.fromRowAndSpend(b, spent, lastDayOfMonth, currentDay);
    });
  }

  async createBudget(userId: string, dto: CreateBudgetDto): Promise<BudgetEntity> {
    const supabase = this.supabaseService.getAdminClient();

    const { data, error } = await supabase
      .from('budgets')
      .insert({
        user_id: userId,
        category_id: dto.categoryId,
        month: dto.month,
        year: dto.year,
        limit_amount: dto.limitAmount,
        notify_threshold_pct: dto.notifyThresholdPct ?? 80,
      })
      .select('*, categories:category_id ( name, icon, color_hex )')
      .single();

    if (error) {
      this.logger.error(`Failed to create budget: ${error.message}`);
      if (error.code === '23505') {
        throw new BadRequestException('A budget for this category and month already exists');
      }
      throw new InternalServerErrorException(error.message);
    }

    const daysInMonth = new Date(dto.year, dto.month, 0).getDate();
    return BudgetEntity.fromRowAndSpend(data, 0, daysInMonth, 1);
  }

  async updateBudget(userId: string, budgetId: string, dto: UpdateBudgetDto): Promise<BudgetEntity> {
    const supabase = this.supabaseService.getAdminClient();

    const updates: Record<string, any> = {};
    if (dto.limitAmount !== undefined) updates.limit_amount = dto.limitAmount;
    if (dto.notifyThresholdPct !== undefined) updates.notify_threshold_pct = dto.notifyThresholdPct;

    const { data, error } = await supabase
      .from('budgets')
      .update(updates)
      .eq('id', budgetId)
      .eq('user_id', userId)
      .select('*, categories:category_id ( name, icon, color_hex )')
      .single();

    if (error || !data) {
      throw new NotFoundException(`Budget '${budgetId}' not found`);
    }

    const daysInMonth = new Date(data.year, data.month, 0).getDate();
    return BudgetEntity.fromRowAndSpend(data, 0, daysInMonth, 1);
  }

  async deleteBudget(userId: string, budgetId: string): Promise<{ success: boolean; message: string }> {
    const supabase = this.supabaseService.getAdminClient();

    const { error } = await supabase
      .from('budgets')
      .delete()
      .eq('id', budgetId)
      .eq('user_id', userId);

    if (error) {
      this.logger.error(`Failed to delete budget ${budgetId}: ${error.message}`);
      throw new InternalServerErrorException(error.message);
    }

    return {
      success: true,
      message: 'Budget successfully deleted',
    };
  }
}
