import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/budget_entity.dart';

class BudgetsRepository {
  final ApiClient _apiClient;

  BudgetsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<BudgetEntity>> getBudgets({required int month, required int year}) async {
    try {
      final response = await _apiClient.dio.get(
        '/budgets',
        queryParameters: {'month': month, 'year': year},
      );
      final List data = response.data['data'] ?? response.data ?? [];
      return data.map((json) => BudgetEntity.fromJson(json)).toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] ?? e.message ?? 'Failed to load budgets';
      throw Exception(msg);
    }
  }

  Future<BudgetEntity> createBudget({
    required String categoryId,
    required int month,
    required int year,
    required double limitAmount,
    int notifyThresholdPct = 80,
  }) async {
    try {
      final response = await _apiClient.dio.post('/budgets', data: {
        'categoryId': categoryId,
        'month': month,
        'year': year,
        'limitAmount': limitAmount,
        'notifyThresholdPct': notifyThresholdPct,
      });

      final data = response.data['data'] ?? response.data;
      return BudgetEntity.fromJson(data);
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] ?? e.message ?? 'Failed to create budget';
      throw Exception(msg);
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await _apiClient.dio.delete('/budgets/$budgetId');
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] ?? e.message ?? 'Failed to delete budget';
      throw Exception(msg);
    }
  }
}
