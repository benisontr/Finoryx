import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_analytics_entity.dart';

class DashboardState {
  final DashboardAnalyticsEntity? analytics;
  final bool isLoading;
  final bool isBalanceHidden;
  final String? error;

  const DashboardState({
    this.analytics,
    this.isLoading = false,
    this.isBalanceHidden = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardAnalyticsEntity? analytics,
    bool? isLoading,
    bool? isBalanceHidden,
    String? error,
  }) {
    return DashboardState(
      analytics: analytics ?? this.analytics,
      isLoading: isLoading ?? this.isLoading,
      isBalanceHidden: isBalanceHidden ?? this.isBalanceHidden,
      error: error,
    );
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardController(repository);
});

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardController(this._repository) : super(const DashboardState()) {
    loadDashboard();
  }

  Future<void> loadDashboard({int? month, int? year}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final analytics = await _repository.getDashboardSummary(
        month: month,
        year: year,
      );
      state = state.copyWith(analytics: analytics, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void toggleBalanceVisibility() {
    state = state.copyWith(isBalanceHidden: !state.isBalanceHidden);
  }
}
