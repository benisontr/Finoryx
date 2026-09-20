import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transactions_repository.dart';
import '../domain/transaction_entity.dart';
import '../../accounts/presentation/accounts_controller.dart';
import '../../dashboard/presentation/dashboard_controller.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository();
});

class TransactionsState {
  final bool isLoading;
  final List<TransactionEntity> transactions;
  final String? errorMessage;

  const TransactionsState({
    this.isLoading = false,
    this.transactions = const [],
    this.errorMessage,
  });

  TransactionsState copyWith({
    bool? isLoading,
    List<TransactionEntity>? transactions,
    String? errorMessage,
  }) {
    return TransactionsState(
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage,
    );
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionsRepository _repository;
  final Ref _ref;

  TransactionsNotifier({
    required TransactionsRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const TransactionsState()) {
    loadTransactions();
  }

  Future<void> loadTransactions({TransactionType? type, String? accountId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final txs = await _repository.getTransactions(type: type, accountId: accountId);
      state = state.copyWith(isLoading: false, transactions: txs);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> recordTransaction({
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createTransaction(
        accountId: accountId,
        destinationAccountId: destinationAccountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        feeAmount: feeAmount,
        description: description,
        tags: tags,
        transactionDate: transactionDate,
      );

      // Refresh transactions and account balances in parallel
      await Future.wait([
        loadTransactions(),
        _ref.read(accountsNotifierProvider.notifier).loadAccounts(),
        _ref.read(dashboardControllerProvider.notifier).loadDashboard(),
      ]);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _repository.deleteTransaction(transactionId);
      await Future.wait([
        loadTransactions(),
        _ref.read(accountsNotifierProvider.notifier).loadAccounts(),
        _ref.read(dashboardControllerProvider.notifier).loadDashboard(),
      ]);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final transactionsNotifierProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier(
    repository: ref.watch(transactionsRepositoryProvider),
    ref: ref,
  );
});
