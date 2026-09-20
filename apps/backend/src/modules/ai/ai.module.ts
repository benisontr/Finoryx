import { Module } from '@nestjs/common';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { AiToolsService } from './ai-tools.service';
import { AnalyticsModule } from '../analytics/analytics.module';
import { GoalsModule } from '../goals/goals.module';
import { BudgetsModule } from '../budgets/budgets.module';

@Module({
  imports: [AnalyticsModule, GoalsModule, BudgetsModule],
  controllers: [AiController],
  providers: [AiService, AiToolsService],
  exports: [AiService, AiToolsService],
})
export class AiModule {}
