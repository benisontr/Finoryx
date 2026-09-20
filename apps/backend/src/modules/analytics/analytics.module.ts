import { Module } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { AnalyticsController } from './analytics.controller';
import { BudgetsModule } from '../budgets/budgets.module';
import { GoalsModule } from '../goals/goals.module';

@Module({
  imports: [BudgetsModule, GoalsModule],
  controllers: [AnalyticsController],
  providers: [AnalyticsService],
  exports: [AnalyticsService],
})
export class AnalyticsModule {}
