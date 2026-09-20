import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/goal_entity.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository();
});

class GoalsRepository {
  final ApiClient _apiClient;

  GoalsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<GoalEntity> goals, GoalsSummary summary})> getGoals() async {
    try {
      final response = await _apiClient.dio.get('/goals');
      final data = ApiClient.extractData(response) as Map<String, dynamic>;
      
      final goalsJson = (data['goals'] as List<dynamic>?) ?? [];
      final summaryJson = (data['summary'] as Map<String, dynamic>?) ?? {};

      final goals = goalsJson
          .map((item) => GoalEntity.fromJson(item as Map<String, dynamic>))
          .toList();

      final summary = GoalsSummary.fromJson(summaryJson);

      return (goals: goals, summary: summary);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to load goals');
    }
  }

  Future<GoalEntity> createGoal({
    required String name,
    required double targetAmount,
    double? currentAmount,
    required String targetDate,
    String? linkedAccountId,
  }) async {
    try {
      final response = await _apiClient.dio.post('/goals', data: {
        'name': name,
        'targetAmount': targetAmount,
        if (currentAmount != null) 'currentAmount': currentAmount,
        'targetDate': targetDate,
        if (linkedAccountId != null) 'linkedAccountId': linkedAccountId,
      });

      final data = ApiClient.extractData(response) as Map<String, dynamic>;
      return GoalEntity.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to create goal');
    }
  }

  Future<GoalEntity> updateGoal({
    required String id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? targetDate,
    String? linkedAccountId,
    bool? isCompleted,
  }) async {
    try {
      final response = await _apiClient.dio.patch('/goals/$id', data: {
        if (name != null) 'name': name,
        if (targetAmount != null) 'targetAmount': targetAmount,
        if (currentAmount != null) 'currentAmount': currentAmount,
        if (targetDate != null) 'targetDate': targetDate,
        if (linkedAccountId != null) 'linkedAccountId': linkedAccountId,
        if (isCompleted != null) 'isCompleted': isCompleted,
      });

      final data = ApiClient.extractData(response) as Map<String, dynamic>;
      return GoalEntity.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to update goal');
    }
  }

  Future<GoalEntity> contributeGoal({
    required String id,
    required double amount,
    String? sourceAccountId,
  }) async {
    try {
      final response = await _apiClient.dio.post('/goals/$id/contribute', data: {
        'amount': amount,
        if (sourceAccountId != null) 'sourceAccountId': sourceAccountId,
      });

      final data = ApiClient.extractData(response) as Map<String, dynamic>;
      return GoalEntity.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to contribute to goal');
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _apiClient.dio.delete('/goals/$id');
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to delete goal');
    }
  }
}
