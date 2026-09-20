export enum BurnRateStatus {
  HEALTHY = 'HEALTHY',     // Spend pace is below or matches elapsed month percentage
  WARNING = 'WARNING',     // Spend pace exceeds month elapsed percentage by > 15%
  EXCEEDED = 'EXCEEDED',   // Spent > 100% of budget limit
}

export class BudgetEntity {
  id: string;
  userId: string;
  categoryId: string;
  categoryName?: string;
  categoryIcon?: string;
  categoryColorHex?: string;
  month: number;
  year: number;
  limitAmount: number;
  spentAmount: number;
  remainingAmount: number;
  spentPercentage: number;
  monthElapsedPercentage: number;
  burnRateStatus: BurnRateStatus;
  projectedSpend: number;
  notifyThresholdPct: number;
  createdAt: string;
  updatedAt: string;

  static fromRowAndSpend(
    budgetRow: any,
    spentAmount: number,
    daysInMonth: number,
    currentDay: number,
  ): BudgetEntity {
    const limit = parseFloat(budgetRow.limit_amount) || 0.0;
    const remaining = Math.max(0, limit - spentAmount);
    const spentPct = limit > 0 ? (spentAmount / limit) * 100 : 0;
    const monthElapsedPct = Math.min(100, Math.max(0, (currentDay / daysInMonth) * 100));

    // Projected spend: based on daily burn rate
    const dailyBurnRate = currentDay > 0 ? spentAmount / currentDay : 0;
    const projectedSpend = dailyBurnRate * daysInMonth;

    let status = BurnRateStatus.HEALTHY;
    if (spentAmount >= limit) {
      status = BurnRateStatus.EXCEEDED;
    } else if (spentPct > monthElapsedPct + 15) {
      status = BurnRateStatus.WARNING;
    }

    return {
      id: budgetRow.id,
      userId: budgetRow.user_id,
      categoryId: budgetRow.category_id,
      categoryName: budgetRow.categories?.name,
      categoryIcon: budgetRow.categories?.icon,
      categoryColorHex: budgetRow.categories?.color_hex,
      month: budgetRow.month,
      year: budgetRow.year,
      limitAmount: limit,
      spentAmount: spentAmount,
      remainingAmount: remaining,
      spentPercentage: parseFloat(spentPct.toFixed(1)),
      monthElapsedPercentage: parseFloat(monthElapsedPct.toFixed(1)),
      burnRateStatus: status,
      projectedSpend: parseFloat(projectedSpend.toFixed(2)),
      notifyThresholdPct: budgetRow.notify_threshold_pct || 80,
      createdAt: budgetRow.created_at,
      updatedAt: budgetRow.updated_at,
    };
  }
}
