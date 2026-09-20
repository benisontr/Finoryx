import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/transaction_entity.dart';

class TransactionsRepository {
  final ApiClient _apiClient;

  TransactionsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<TransactionEntity>> getTransactions({
    int page = 1,
    int limit = 20,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    String? search,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/transactions',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (accountId != null) 'accountId': accountId,
          if (categoryId != null) 'categoryId': categoryId,
          if (type != null) 'type': type.toApiString(),
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final List data = ApiClient.extractData(response) ?? [];
      return data.map((json) => TransactionEntity.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to load transactions');
    }
  }

  Future<TransactionEntity> createTransaction({
    required String accountId,
    String? destinationAccountId,
    String? categoryId,
    required TransactionType type,
    required double amount,
    double feeAmount = 0.0,
    String? description,
    List<String> tags = const [],
    DateTime? transactionDate,
  }) async {
    try {
      final response = await _apiClient.dio.post('/transactions', data: {
        'accountId': accountId,
        'destinationAccountId': destinationAccountId,
        'categoryId': categoryId,
        'type': type.toApiString(),
        'amount': amount,
        'feeAmount': feeAmount,
        'description': description,
        'tags': tags,
        'transactionDate': (transactionDate ?? DateTime.now()).toIso8601String(),
      });

      final data = ApiClient.extractData(response);
      return TransactionEntity.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to save transaction');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _apiClient.dio.delete('/transactions/$transactionId');
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to delete transaction');
    }
  }
}
