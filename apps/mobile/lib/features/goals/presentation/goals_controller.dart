import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/goals_repository.dart';
import '../domain/goal_entity.dart';

class GoalsState {
  final List<GoalEntity> goals;
  final GoalsSummary summary;
  final bool isLoading;
  final String? error;

  const GoalsState({
    this.goals = const [],
    this.summary = const GoalsSummary(
      totalTargetAmount: 0,
      totalCurrentAmount: 0,
      totalRemainingAmount: 0,
      overallProgressPercentage: 0,
      activeGoalsCount: 0,
      completedGoalsCount: 0,
    ),
    this.isLoading = false,
    this.error,
  });

  GoalsState copyWith({
    List<GoalEntity>? goals,
    GoalsSummary? summary,
    bool? isLoading,
    String? error,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final goalsControllerProvider =
    StateNotifierProvider<GoalsController, GoalsState>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  return GoalsController(repository);
});

final goalsNotifierProvider = goalsControllerProvider;

class GoalsController extends StateNotifier<GoalsState> {
  final GoalsRepository _repository;

  GoalsController(this._repository) : super(const GoalsState()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repository.getGoals();
      state = state.copyWith(
        goals: res.goals,
        summary: res.summary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createGoal({
    required String name,
    required double targetAmount,
    double? currentAmount,
    required String targetDate,
    String? linkedAccountId,
  }) async {
    try {
      await _repository.createGoal(
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: targetDate,
        linkedAccountId: linkedAccountId,
      );
      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> contribute({
    required String id,
    required double amount,
    String? sourceAccountId,
  }) async {
    try {
      await _repository.contributeGoal(
        id: id,
        amount: amount,
        sourceAccountId: sourceAccountId,
      );
      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteGoal(String id) async {
    try {
      await _repository.deleteGoal(id);
      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}
