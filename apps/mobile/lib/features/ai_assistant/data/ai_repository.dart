import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/ai_message_entity.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository();
});

class AiRepository {
  final ApiClient _apiClient;

  AiRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Send message to grounded AI Copilot
  Future<AiMessageEntity> sendMessage(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/ai/chat',
        data: {
          'message': message,
          if (context != null) 'context': context,
        },
      );

      final data = ApiClient.extractData(response) as Map<String, dynamic>;
      return AiMessageEntity.fromJson(
        data,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: AiSender.assistant,
      );
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to connect to Finoryx AI');
    }
  }

  /// Run dedicated purchase affordability check
  Future<AiStructuredInsightEntity> checkAffordability({
    required double amount,
    String? categoryId,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/ai/affordability-check',
        data: {
          'amount': amount,
          if (categoryId != null) 'categoryId': categoryId,
          if (description != null) 'description': description,
        },
      );

      final data = ApiClient.extractData(response) as Map<String, dynamic>;
      return AiStructuredInsightEntity.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to evaluate affordability');
    }
  }

  /// Retrieve proactive insights for dashboard widget
  Future<List<AiStructuredInsightEntity>> getProactiveInsights() async {
    try {
      final response = await _apiClient.dio.get('/ai/insights');
      final data = ApiClient.extractData(response) as List<dynamic>;
      return data
          .map((item) => AiStructuredInsightEntity.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to load AI insights');
    }
  }
}
