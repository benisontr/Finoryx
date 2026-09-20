export enum GoalPaceStatus {
  COMPLETED = 'COMPLETED', // Target reached or marked complete
  AHEAD = 'AHEAD',         // Savings is ahead of expected pace (> 105% of scheduled pace)
  ON_TRACK = 'ON_TRACK',   // Savings is on schedule (90% - 105% of scheduled pace)
  BEHIND = 'BEHIND',       // Savings is behind schedule (< 90% of scheduled pace)
  OVERDUE = 'OVERDUE',     // Target date passed and target not achieved
}

export class GoalEntity {
  id: string;
  userId: string;
  linkedAccountId?: string;
  linkedAccountName?: string;
  name: string;
  targetAmount: number;
  currentAmount: number;
  remainingAmount: number;
  progressPercentage: number;
  targetDate: string;
  daysRemaining: number;
  paceStatus: GoalPaceStatus;
  expectedPaceAmount: number;
  paceDifference: number; // positive = ahead, negative = shortfall
  requiredMonthlySavings: number;
  requiredWeeklySavings: number;
  requiredDailySavings: number;
  isCompleted: boolean;
  createdAt: string;
  updatedAt: string;

  static fromRow(goalRow: any, linkedAccountName?: string, referenceDate: Date = new Date()): GoalEntity {
    const targetAmount = parseFloat(goalRow.target_amount) || 0.0;
    const currentAmount = parseFloat(goalRow.current_amount) || 0.0;
    const isCompleted = goalRow.is_completed || currentAmount >= targetAmount;
    const remainingAmount = Math.max(0, targetAmount - currentAmount);
    const progressPercentage = targetAmount > 0 ? Math.min(100, (currentAmount / targetAmount) * 100) : 0;

    const createdAt = new Date(goalRow.created_at || referenceDate);
    const targetDate = new Date(goalRow.target_date);
    
    // Day calculations
    const msPerDay = 1000 * 60 * 60 * 24;
    const totalDays = Math.max(1, Math.ceil((targetDate.getTime() - createdAt.getTime()) / msPerDay));
    const elapsedDays = Math.max(0, Math.min(totalDays, Math.ceil((referenceDate.getTime() - createdAt.getTime()) / msPerDay)));
    const daysRemaining = Math.max(0, Math.ceil((targetDate.getTime() - referenceDate.getTime()) / msPerDay));

    // Expected pace based on elapsed time vs total time
    const expectedPaceAmount = (elapsedDays / totalDays) * targetAmount;
    const paceDifference = currentAmount - expectedPaceAmount;

    // Determine Pace Status
    let paceStatus: GoalPaceStatus;
    if (isCompleted) {
      paceStatus = GoalPaceStatus.COMPLETED;
    } else if (daysRemaining === 0 && currentAmount < targetAmount) {
      paceStatus = GoalPaceStatus.OVERDUE;
    } else if (expectedPaceAmount <= 0) {
      paceStatus = currentAmount > 0 ? GoalPaceStatus.AHEAD : GoalPaceStatus.ON_TRACK;
    } else if (currentAmount >= expectedPaceAmount * 1.05) {
      paceStatus = GoalPaceStatus.AHEAD;
    } else if (currentAmount >= expectedPaceAmount * 0.9) {
      paceStatus = GoalPaceStatus.ON_TRACK;
    } else {
      paceStatus = GoalPaceStatus.BEHIND;
    }

    // Required rates to reach goal by target date
    const monthsRemaining = Math.max(0.1, daysRemaining / 30.4375);
    const weeksRemaining = Math.max(0.1, daysRemaining / 7);
    const requiredMonthlySavings = remainingAmount > 0 ? remainingAmount / monthsRemaining : 0;
    const requiredWeeklySavings = remainingAmount > 0 ? remainingAmount / weeksRemaining : 0;
    const requiredDailySavings = remainingAmount > 0 ? remainingAmount / Math.max(1, daysRemaining) : 0;

    const entity = new GoalEntity();
    entity.id = goalRow.id;
    entity.userId = goalRow.user_id;
    entity.linkedAccountId = goalRow.linked_account_id;
    entity.linkedAccountName = linkedAccountName || goalRow.accounts?.name;
    entity.name = goalRow.name;
    entity.targetAmount = targetAmount;
    entity.currentAmount = currentAmount;
    entity.remainingAmount = remainingAmount;
    entity.progressPercentage = Math.round(progressPercentage * 100) / 100;
    entity.targetDate = goalRow.target_date;
    entity.daysRemaining = daysRemaining;
    entity.paceStatus = paceStatus;
    entity.expectedPaceAmount = Math.round(expectedPaceAmount * 100) / 100;
    entity.paceDifference = Math.round(paceDifference * 100) / 100;
    entity.requiredMonthlySavings = Math.round(requiredMonthlySavings * 100) / 100;
    entity.requiredWeeklySavings = Math.round(requiredWeeklySavings * 100) / 100;
    entity.requiredDailySavings = Math.round(requiredDailySavings * 100) / 100;
    entity.isCompleted = isCompleted;
    entity.createdAt = goalRow.created_at;
    entity.updatedAt = goalRow.updated_at;

    return entity;
  }
}
