import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { SupabaseService } from '../../database/supabase.service';
import { CreateGoalDto } from './dto/create-goal.dto';
import { UpdateGoalDto } from './dto/update-goal.dto';
import { ContributeGoalDto } from './dto/contribute-goal.dto';
import { GoalEntity } from './entities/goal.entity';

@Injectable()
export class GoalsService {
  private readonly logger = new Logger(GoalsService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(userId: string): Promise<{
    goals: GoalEntity[];
    summary: {
      totalTargetAmount: number;
      totalCurrentAmount: number;
      totalRemainingAmount: number;
      overallProgressPercentage: number;
      activeGoalsCount: number;
      completedGoalsCount: number;
    };
  }> {
    const supabase = this.supabaseService.getAdminClient();
    const { data: rows, error } = await supabase
      .from('goals')
      .select('*, accounts:linked_account_id(name)')
      .eq('user_id', userId)
      .order('is_completed', { ascending: true })
      .order('target_date', { ascending: true });

    if (error) {
      this.logger.error(`Failed to fetch goals: ${error.message}`);
      throw new BadRequestException(`Failed to fetch goals: ${error.message}`);
    }

    const goals = (rows || []).map((row) => GoalEntity.fromRow(row));

    let totalTarget = 0;
    let totalCurrent = 0;
    let activeCount = 0;
    let completedCount = 0;

    for (const g of goals) {
      totalTarget += g.targetAmount;
      totalCurrent += g.currentAmount;
      if (g.isCompleted) {
        completedCount++;
      } else {
        activeCount++;
      }
    }

    const totalRemaining = Math.max(0, totalTarget - totalCurrent);
    const overallProgress = totalTarget > 0 ? (totalCurrent / totalTarget) * 100 : 0;

    return {
      goals,
      summary: {
        totalTargetAmount: Math.round(totalTarget * 100) / 100,
        totalCurrentAmount: Math.round(totalCurrent * 100) / 100,
        totalRemainingAmount: Math.round(totalRemaining * 100) / 100,
        overallProgressPercentage: Math.round(overallProgress * 100) / 100,
        activeGoalsCount: activeCount,
        completedGoalsCount: completedCount,
      },
    };
  }

  async findOne(userId: string, id: string): Promise<GoalEntity> {
    const supabase = this.supabaseService.getAdminClient();
    const { data: row, error } = await supabase
      .from('goals')
      .select('*, accounts:linked_account_id(name)')
      .eq('id', id)
      .eq('user_id', userId)
      .single();

    if (error || !row) {
      throw new NotFoundException(`Goal with ID ${id} not found`);
    }

    return GoalEntity.fromRow(row);
  }

  async create(userId: string, dto: CreateGoalDto): Promise<GoalEntity> {
    const supabase = this.supabaseService.getAdminClient();

    // Validate linked account if provided
    if (dto.linkedAccountId) {
      const { data: account, error: accError } = await supabase
        .from('accounts')
        .select('id')
        .eq('id', dto.linkedAccountId)
        .eq('user_id', userId)
        .single();

      if (accError || !account) {
        throw new BadRequestException('Linked account not found or does not belong to user');
      }
    }

    const currentAmount = dto.currentAmount || 0;
    const isCompleted = currentAmount >= dto.targetAmount;

    const { data: row, error } = await supabase
      .from('goals')
      .insert({
        user_id: userId,
        name: dto.name,
        target_amount: dto.targetAmount,
        current_amount: currentAmount,
        target_date: dto.targetDate,
        linked_account_id: dto.linkedAccountId || null,
        is_completed: isCompleted,
      })
      .select('*, accounts:linked_account_id(name)')
      .single();

    if (error) {
      this.logger.error(`Failed to create goal: ${error.message}`);
      throw new BadRequestException(`Failed to create goal: ${error.message}`);
    }

    return GoalEntity.fromRow(row);
  }

  async update(userId: string, id: string, dto: UpdateGoalDto): Promise<GoalEntity> {
    const existing = await this.findOne(userId, id);
    const supabase = this.supabaseService.getAdminClient();

    const updatePayload: any = {};
    if (dto.name !== undefined) updatePayload.name = dto.name;
    if (dto.targetAmount !== undefined) updatePayload.target_amount = dto.targetAmount;
    if (dto.currentAmount !== undefined) updatePayload.current_amount = dto.currentAmount;
    if (dto.targetDate !== undefined) updatePayload.target_date = dto.targetDate;
    if (dto.linkedAccountId !== undefined) updatePayload.linked_account_id = dto.linkedAccountId;
    if (dto.isCompleted !== undefined) updatePayload.is_completed = dto.isCompleted;

    const target = dto.targetAmount !== undefined ? dto.targetAmount : existing.targetAmount;
    const current = dto.currentAmount !== undefined ? dto.currentAmount : existing.currentAmount;
    if (dto.isCompleted === undefined && current >= target) {
      updatePayload.is_completed = true;
    }

    const { data: row, error } = await supabase
      .from('goals')
      .update(updatePayload)
      .eq('id', id)
      .eq('user_id', userId)
      .select('*, accounts:linked_account_id(name)')
      .single();

    if (error) {
      this.logger.error(`Failed to update goal: ${error.message}`);
      throw new BadRequestException(`Failed to update goal: ${error.message}`);
    }

    return GoalEntity.fromRow(row);
  }

  async contribute(userId: string, id: string, dto: ContributeGoalDto): Promise<GoalEntity> {
    const goal = await this.findOne(userId, id);
    const supabase = this.supabaseService.getAdminClient();

    // If source account is provided, decrement balance atomically
    if (dto.sourceAccountId) {
      const { data: account, error: accErr } = await supabase
        .from('accounts')
        .select('*')
        .eq('id', dto.sourceAccountId)
        .eq('user_id', userId)
        .single();

      if (accErr || !account) {
        throw new BadRequestException('Source account not found');
      }

      const accBalance = parseFloat(account.current_balance) || 0;
      if (accBalance < dto.amount) {
        throw new BadRequestException(`Insufficient funds in source account (Balance: ${accBalance}, Required: ${dto.amount})`);
      }

      const newBalance = accBalance - dto.amount;
      const { error: updateAccErr } = await supabase
        .from('accounts')
        .update({ current_balance: newBalance })
        .eq('id', dto.sourceAccountId);

      if (updateAccErr) {
        throw new BadRequestException(`Failed to deduct funds from source account: ${updateAccErr.message}`);
      }
    }

    const newCurrentAmount = goal.currentAmount + dto.amount;
    const isCompleted = newCurrentAmount >= goal.targetAmount;

    const { data: row, error } = await supabase
      .from('goals')
      .update({
        current_amount: newCurrentAmount,
        is_completed: isCompleted,
      })
      .eq('id', id)
      .eq('user_id', userId)
      .select('*, accounts:linked_account_id(name)')
      .single();

    if (error) {
      this.logger.error(`Failed to record contribution: ${error.message}`);
      throw new BadRequestException(`Failed to record contribution: ${error.message}`);
    }

    return GoalEntity.fromRow(row);
  }

  async remove(userId: string, id: string): Promise<{ success: boolean; message: string }> {
    await this.findOne(userId, id);
    const supabase = this.supabaseService.getAdminClient();

    const { error } = await supabase
      .from('goals')
      .delete()
      .eq('id', id)
      .eq('user_id', userId);

    if (error) {
      this.logger.error(`Failed to delete goal: ${error.message}`);
      throw new BadRequestException(`Failed to delete goal: ${error.message}`);
    }

    return { success: true, message: 'Goal deleted successfully' };
  }
}
