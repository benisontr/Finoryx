import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiToolsService } from './ai-tools.service';
import {
  AiChatResponse,
  AiInsightType,
  AiStructuredInsight,
  AffordabilityStatus,
} from './entities/ai.entity';
import { AiChatDto } from './dto/ai-chat.dto';
import { AffordabilityCheckDto } from './dto/affordability-check.dto';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);

  constructor(
    private readonly configService: ConfigService,
    private readonly aiToolsService: AiToolsService,
  ) {}

  /**
   * Process natural language conversational query with grounded tool calling
   */
  async processChat(userId: string, dto: AiChatDto): Promise<AiChatResponse> {
    const rawMessage = dto.message.trim();
    const lower = rawMessage.toLowerCase();
    const toolsUsed: string[] = [];
    let structuredInsight: AiStructuredInsight | undefined;
    let responseText = '';

    // 1. Intent Detection: Affordability Check
    const affordMatch = lower.match(/(?:can i afford|afford|buy|purchase|spend)\s*(?:₹|\$|eur|inr)?\s*([\d,]+(?:\.\d+)?)/i);
    if (affordMatch || lower.includes('afford')) {
      toolsUsed.push('check_affordability');
      let amount = 0;
      if (affordMatch && affordMatch[1]) {
        amount = parseFloat(affordMatch[1].replace(/,/g, ''));
      }
      if (amount <= 0) {
        amount = 5000;
      }

      const affordability = await this.aiToolsService.checkAffordability(userId, amount);

      let color = '#10B981';
      if (affordability.status === AffordabilityStatus.UNRECOMMENDED) color = '#EF4444';
      else if (affordability.status === AffordabilityStatus.RISKY) color = '#F59E0B';
      else if (affordability.status === AffordabilityStatus.MODERATE) color = '#5B5CE2';

      structuredInsight = {
        type: AiInsightType.AFFORDABILITY_CHECK,
        title: 'AFFORDABILITY DECISION',
        summary: `Evaluation for expenditure of ${amount.toFixed(2)}`,
        statusColor: color,
        affordability,
      };

      responseText = `Based on your real-time ledger balance, ${affordability.budgetImpactMessage} You currently hold a liquid cash buffer of ${affordability.currentLiquidBuffer.toFixed(2)}, and this purchase will leave you with ${affordability.postPurchaseLiquidBuffer.toFixed(2)} in liquid reserves.`;
    }
    // 2. Intent Detection: Savings Goals & Milestones
    else if (
      lower.includes('goal') ||
      lower.includes('saving') ||
      lower.includes('emergency fund') ||
      lower.includes('milestone')
    ) {
      toolsUsed.push('get_savings_goals_pace');
      const goalsPace = await this.aiToolsService.getSavingsGoalsPace(userId);

      structuredInsight = {
        type: AiInsightType.SAVINGS_GOALS_PACE,
        title: 'SAVINGS GOALS PACE ENGINE',
        summary: `${goalsPace.goalCount} total goals (${goalsPace.overallProgressPercentage.toFixed(1)}% funded)`,
        statusColor: '#10B981',
        savingsGoals: goalsPace,
      };

      if (goalsPace.goalCount === 0) {
        responseText = `You currently do not have any active savings goals. You can create targets like an Emergency Fund or Vacation Fund in the Goals section to activate intelligent daily pace tracking.`;
      } else {
        responseText = `You have accumulated ${goalsPace.totalSaved.toFixed(2)} across your savings goals (${goalsPace.overallProgressPercentage.toFixed(1)}% of your ${goalsPace.totalTarget.toFixed(2)} cumulative target). To stay perfectly on schedule across all active goals (${goalsPace.activeGoalNames.join(', ')}), aim to allocate ${goalsPace.requiredDailySavings.toFixed(2)}/day (${goalsPace.requiredMonthlySavings.toFixed(2)}/month).`;
      }
    }
    // 3. Intent Detection: Burn Rate & Budget Pace
    else if (
      lower.includes('burn') ||
      lower.includes('budget') ||
      lower.includes('pace') ||
      lower.includes('spending') ||
      lower.includes('spend the most') ||
      lower.includes('expense')
    ) {
      toolsUsed.push('get_monthly_burn_rate');
      const burnRate = await this.aiToolsService.getMonthlyBurnRate(userId);

      let color = '#10B981';
      if (burnRate.burnStatus === 'EXCEEDED') color = '#EF4444';
      else if (burnRate.burnStatus === 'WARNING') color = '#F59E0B';

      structuredInsight = {
        type: AiInsightType.BURN_RATE_CHECK,
        title: 'MONTHLY BURN RATE ANALYSIS',
        summary: `Spending pace is ${burnRate.burnStatus.toLowerCase()} at ${burnRate.burnRatePercentage.toFixed(1)}%`,
        statusColor: color,
        burnRate,
      };

      responseText = `You have spent ${burnRate.totalMonthlyExpense.toFixed(2)} across day ${burnRate.daysPassedInMonth} of ${burnRate.totalDaysInMonth} this month. Your top category is "${burnRate.topExpenseCategory}". At this velocity, your projected month-end outflow is ${burnRate.projectedMonthEndSpend.toFixed(2)}. Pacing is currently ${burnRate.burnStatus.toLowerCase()}.`;
    }
    // 4. Intent Detection: Net Worth, Liquid Balances, & Overview
    else {
      toolsUsed.push('get_net_worth_and_balances');
      const summary = await this.aiToolsService.getNetWorthAndBalances(userId);

      structuredInsight = {
        type: AiInsightType.FINANCIAL_SUMMARY,
        title: 'FINANCIAL HEALTH SNAPSHOT',
        summary: `Net worth is ${summary.netWorth.toFixed(2)} with a savings rate of ${summary.monthlySavingsRate.toFixed(1)}%`,
        statusColor: '#5B5CE2',
        financialSummary: summary,
      };

      responseText = `I analyzed your complete account ledger. Your total net worth is ${summary.netWorth.toFixed(2)} (Assets: ${summary.totalAssets.toFixed(2)}, Liabilities: ${summary.totalLiabilities.toFixed(2)}). You currently retain a liquid cash cushion of ${summary.liquidBuffer.toFixed(2)} with an overall monthly savings rate of ${summary.monthlySavingsRate.toFixed(1)}%.`;
    }

    return {
      message: responseText,
      timestamp: new Date().toISOString(),
      toolsUsed,
      structuredInsight,
    };
  }

  /**
   * Quick dedicated affordability evaluation endpoint
   */
  async checkAffordability(
    userId: string,
    dto: AffordabilityCheckDto,
  ): Promise<AiStructuredInsight> {
    const payload = await this.aiToolsService.checkAffordability(
      userId,
      dto.amount,
      dto.categoryId,
    );

    let color = '#10B981';
    if (payload.status === AffordabilityStatus.UNRECOMMENDED) color = '#EF4444';
    else if (payload.status === AffordabilityStatus.RISKY) color = '#F59E0B';
    else if (payload.status === AffordabilityStatus.MODERATE) color = '#5B5CE2';

    return {
      type: AiInsightType.AFFORDABILITY_CHECK,
      title: 'AFFORDABILITY DECISION',
      summary: payload.budgetImpactMessage,
      statusColor: color,
      affordability: payload,
    };
  }

  /**
   * Retrieve dynamic proactive insights for dashboard widget
   */
  async getProactiveInsights(userId: string): Promise<AiStructuredInsight[]> {
    const burnRate = await this.aiToolsService.getMonthlyBurnRate(userId);
    const summary = await this.aiToolsService.getNetWorthAndBalances(userId);
    const insights: AiStructuredInsight[] = [];

    if (burnRate.burnStatus === 'WARNING' || burnRate.burnStatus === 'EXCEEDED') {
      insights.push({
        type: AiInsightType.BURN_RATE_CHECK,
        title: 'SPENDING VELOCITY ALERT',
        summary: `Monthly spending is pacing high at ${burnRate.burnRatePercentage.toFixed(1)}% of budget. Highest driver is ${burnRate.topExpenseCategory}.`,
        statusColor: '#EF4444',
        burnRate,
      });
    } else {
      insights.push({
        type: AiInsightType.BURN_RATE_CHECK,
        title: 'OPTIMAL SPENDING PACE',
        summary: `Your spending burn rate is on track at ${burnRate.burnRatePercentage.toFixed(1)}% with ${summary.monthlySavingsRate.toFixed(1)}% savings rate.`,
        statusColor: '#10B981',
        burnRate,
      });
    }

    return insights;
  }
}
