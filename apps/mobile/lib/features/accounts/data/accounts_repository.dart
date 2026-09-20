import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/account_entity.dart';

class AccountsRepository {
  final ApiClient _apiClient;

  AccountsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<AccountEntity>> getAccounts({bool includeArchived = false}) async {
    try {
      final response = await _apiClient.dio.get(
        '/accounts',
        queryParameters: {'includeArchived': includeArchived.toString()},
      );
      final List data = ApiClient.extractData(response) ?? [];
      return data.map((json) => AccountEntity.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to fetch accounts');
    }
  }

  Future<AccountsSummaryEntity> getAccountsSummary() async {
    try {
      final response = await _apiClient.dio.get('/accounts/summary');
      final data = ApiClient.extractData(response) ?? {};
      return AccountsSummaryEntity.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to fetch summary');
    }
  }

  Future<AccountEntity> createAccount({
    required String name,
    required AccountType accountType,
    String currency = 'INR',
    double initialBalance = 0.0,
    double? creditLimit,
    int? billingCycleDay,
  }) async {
    try {
      final response = await _apiClient.dio.post('/accounts', data: {
        'name': name,
        'accountType': accountType.toApiString(),
        'currency': currency,
        'initialBalance': initialBalance,
        'creditLimit': creditLimit,
        'billingCycleDay': billingCycleDay,
      });

      final data = ApiClient.extractData(response);
      return AccountEntity.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to create account');
    }
  }

  Future<AccountEntity> updateAccount({
    required String accountId,
    String? name,
    AccountType? accountType,
    double? creditLimit,
    int? billingCycleDay,
    bool? isArchived,
  }) async {
    try {
      final response = await _apiClient.dio.patch('/accounts/$accountId', data: {
        if (name != null) 'name': name,
        if (accountType != null) 'accountType': accountType.toApiString(),
        if (creditLimit != null) 'creditLimit': creditLimit,
        if (billingCycleDay != null) 'billingCycleDay': billingCycleDay,
        if (isArchived != null) 'isArchived': isArchived,
      });

      final data = ApiClient.extractData(response);
      return AccountEntity.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to update account');
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await _apiClient.dio.delete('/accounts/$accountId');
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to delete account');
    }
  }
}
