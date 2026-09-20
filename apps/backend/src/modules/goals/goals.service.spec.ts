import { Test, TestingModule } from '@nestjs/testing';
import { GoalsService } from './goals.service';
import { SupabaseService } from '../../database/supabase.service';
import { GoalEntity, GoalPaceStatus } from './entities/goal.entity';

describe('GoalsService & GoalEntity Savings Pace Engine', () => {
  let service: GoalsService;
  let mockSupabase: any;

  beforeEach(async () => {
    mockSupabase = {
      from: jest.fn().mockReturnThis(),
      select: jest.fn().mockReturnThis(),
      insert: jest.fn().mockReturnThis(),
      update: jest.fn().mockReturnThis(),
      delete: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      order: jest.fn().mockReturnThis(),
      single: jest.fn(),
    };

    const mockSupabaseService = {
      getAdminClient: jest.fn().mockReturnValue(mockSupabase),
      getClient: jest.fn().mockReturnValue(mockSupabase),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GoalsService,
        {
          provide: SupabaseService,
          useValue: mockSupabaseService,
        },
      ],
    }).compile();

    service = module.get<GoalsService>(GoalsService);
  });

  describe('GoalEntity Savings Pace Logic', () => {
    const referenceDate = new Date('2026-06-15T00:00:00Z');

    it('should classify as COMPLETED when current_amount >= target_amount', () => {
      const row = {
        id: 'goal-1',
        user_id: 'user-1',
        name: 'Emergency Fund',
        target_amount: 10000,
        current_amount: 10000,
        target_date: '2026-12-31',
        is_completed: false,
        created_at: '2026-01-01T00:00:00Z',
      };

      const entity = GoalEntity.fromRow(row, undefined, referenceDate);
      expect(entity.paceStatus).toBe(GoalPaceStatus.COMPLETED);
      expect(entity.isCompleted).toBe(true);
      expect(entity.progressPercentage).toBe(100);
      expect(entity.remainingAmount).toBe(0);
    });

    it('should classify as OVERDUE when target date is in the past and target not reached', () => {
      const row = {
        id: 'goal-2',
        user_id: 'user-1',
        name: 'Past Vacation',
        target_amount: 5000,
        current_amount: 2000,
        target_date: '2026-05-01',
        is_completed: false,
        created_at: '2026-01-01T00:00:00Z',
      };

      const entity = GoalEntity.fromRow(row, undefined, referenceDate);
      expect(entity.paceStatus).toBe(GoalPaceStatus.OVERDUE);
      expect(entity.daysRemaining).toBe(0);
    });

    it('should classify as AHEAD when savings exceed expected pace by > 5%', () => {
      const row = {
        id: 'goal-3',
        user_id: 'user-1',
        name: 'New Car',
        target_amount: 10000,
        current_amount: 6000,
        target_date: '2026-12-31',
        is_completed: false,
        created_at: '2026-01-01T00:00:00Z',
      };

      const entity = GoalEntity.fromRow(row, undefined, referenceDate);
      expect(entity.paceStatus).toBe(GoalPaceStatus.AHEAD);
      expect(entity.paceDifference).toBeGreaterThan(0);
    });

    it('should classify as BEHIND when savings fall below 90% of expected pace', () => {
      const row = {
        id: 'goal-4',
        user_id: 'user-1',
        name: 'House Down Payment',
        target_amount: 10000,
        current_amount: 2000,
        target_date: '2026-12-31',
        is_completed: false,
        created_at: '2026-01-01T00:00:00Z',
      };

      const entity = GoalEntity.fromRow(row, undefined, referenceDate);
      expect(entity.paceStatus).toBe(GoalPaceStatus.BEHIND);
      expect(entity.paceDifference).toBeLessThan(0);
      expect(entity.requiredMonthlySavings).toBeGreaterThan(0);
    });
  });

  describe('findAll', () => {
    it('should return goals list and calculated summary statistics', async () => {
      const mockGoals = [
        {
          id: 'g-1',
          user_id: 'user-1',
          name: 'Vacation',
          target_amount: '2000.00',
          current_amount: '1000.00',
          target_date: '2026-12-31',
          is_completed: false,
          created_at: '2026-01-01T00:00:00Z',
        },
        {
          id: 'g-2',
          user_id: 'user-1',
          name: 'Gadget',
          target_amount: '1000.00',
          current_amount: '1000.00',
          target_date: '2026-06-01',
          is_completed: true,
          created_at: '2026-01-01T00:00:00Z',
        },
      ];

      // Since order is chained twice, the second call should resolve with data
      mockSupabase.order
        .mockReturnValueOnce(mockSupabase)
        .mockResolvedValueOnce({ data: mockGoals, error: null });

      const result = await service.findAll('user-1');

      expect(result.goals).toHaveLength(2);
      expect(result.summary.totalTargetAmount).toBe(3000);
      expect(result.summary.totalCurrentAmount).toBe(2000);
      expect(result.summary.totalRemainingAmount).toBe(1000);
      expect(result.summary.activeGoalsCount).toBe(1);
      expect(result.summary.completedGoalsCount).toBe(1);
    });
  });

  describe('contribute', () => {
    it('should increase current_amount and complete if target reached', async () => {
      const existingGoal = {
        id: 'g-1',
        user_id: 'user-1',
        name: 'Laptop',
        target_amount: '1500.00',
        current_amount: '1200.00',
        target_date: '2026-12-31',
        is_completed: false,
        created_at: '2026-01-01T00:00:00Z',
      };

      mockSupabase.single
        .mockResolvedValueOnce({ data: existingGoal, error: null }) // findOne
        .mockResolvedValueOnce({
          data: {
            ...existingGoal,
            current_amount: '1500.00',
            is_completed: true,
          },
          error: null,
        }); // update

      const result = await service.contribute('user-1', 'g-1', { amount: 300 });

      expect(result.currentAmount).toBe(1500);
      expect(result.isCompleted).toBe(true);
      expect(result.paceStatus).toBe(GoalPaceStatus.COMPLETED);
    });
  });
});
