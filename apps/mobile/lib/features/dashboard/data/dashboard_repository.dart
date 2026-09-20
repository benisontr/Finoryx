import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/dashboard_analytics_entity.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<DashboardAnalyticsEntity> getDashboardSummary({
    int? month,
    int? year,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/analytics/dashboard',
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );

      final data = ApiClient.extractData(response) as Map<String, dynamic>;
      return DashboardAnalyticsEntity.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to load dashboard summary');
    }
  }
}
