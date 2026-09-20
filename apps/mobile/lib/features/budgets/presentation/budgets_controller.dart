import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/budgets_repository.dart';
import '../domain/budget_entity.dart';

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository();
});

class BudgetsState {
  final bool isLoading;
  final List<BudgetEntity> budgets;
  final int selectedMonth;
  final int selectedYear;
  final String? errorMessage;

  const BudgetsState({
    this.isLoading = false,
    this.budgets = const [],
    this.selectedMonth = 9,
    this.selectedYear = 2026,
    this.errorMessage,
  });

  double get totalBudgeted => budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
  double get totalSpent => budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
  double get totalRemaining => budgets.fold(0.0, (sum, b) => sum + b.remainingAmount);

  BudgetsState copyWith({
    bool? isLoading,
    List<BudgetEntity>? budgets,
    int? selectedMonth,
    int? selectedYear,
    String? errorMessage,
  }) {
    return BudgetsState(
      isLoading: isLoading ?? this.isLoading,
      budgets: budgets ?? this.budgets,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      errorMessage: errorMessage,
    );
  }
}

class BudgetsNotifier extends StateNotifier<BudgetsState> {
  final BudgetsRepository _repository;

  BudgetsNotifier({required BudgetsRepository repository})
      : _repository = repository,
        super(BudgetsState(
          selectedMonth: DateTime.now().month,
          selectedYear: DateTime.now().year,
        )) {
    loadBudgets();
  }

  Future<void> loadBudgets({int? month, int? year}) async {
    final m = month ?? state.selectedMonth;
    final y = year ?? state.selectedYear;

    state = state.copyWith(isLoading: true, selectedMonth: m, selectedYear: y, errorMessage: null);
    try {
      final list = await _repository.getBudgets(month: m, year: y);
      state = state.copyWith(isLoading: false, budgets: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createBudget({
    required String categoryId,
    required double limitAmount,
    int notifyThresholdPct = 80,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createBudget(
        categoryId: categoryId,
        month: state.selectedMonth,
        year: state.selectedYear,
        limitAmount: limitAmount,
        notifyThresholdPct: notifyThresholdPct,
      );
      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteBudget(String budgetId) async {
    try {
      await _repository.deleteBudget(budgetId);
      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final budgetsNotifierProvider = StateNotifierProvider<BudgetsNotifier, BudgetsState>((ref) {
  return BudgetsNotifier(repository: ref.watch(budgetsRepositoryProvider));
});
