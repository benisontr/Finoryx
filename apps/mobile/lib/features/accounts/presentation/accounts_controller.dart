import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/accounts_repository.dart';
import '../domain/account_entity.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository();
});

class AccountsState {
  final bool isLoading;
  final List<AccountEntity> accounts;
  final AccountsSummaryEntity? summary;
  final String? errorMessage;

  const AccountsState({
    this.isLoading = false,
    this.accounts = const [],
    this.summary,
    this.errorMessage,
  });

  AccountsState copyWith({
    bool? isLoading,
    List<AccountEntity>? accounts,
    AccountsSummaryEntity? summary,
    String? errorMessage,
  }) {
    return AccountsState(
      isLoading: isLoading ?? this.isLoading,
      accounts: accounts ?? this.accounts,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
    );
  }
}

class AccountsNotifier extends StateNotifier<AccountsState> {
  final AccountsRepository _repository;

  AccountsNotifier({required AccountsRepository repository})
      : _repository = repository,
        super(const AccountsState()) {
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final accountsFuture = _repository.getAccounts();
      final summaryFuture = _repository.getAccountsSummary();

      final results = await Future.wait([accountsFuture, summaryFuture]);
      final accounts = results[0] as List<AccountEntity>;
      final summary = results[1] as AccountsSummaryEntity;

      state = state.copyWith(
        isLoading: false,
        accounts: accounts,
        summary: summary,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createAccount({
    required String name,
    required AccountType accountType,
    String currency = 'INR',
    double initialBalance = 0.0,
    double? creditLimit,
    int? billingCycleDay,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createAccount(
        name: name,
        accountType: accountType,
        currency: currency,
        initialBalance: initialBalance,
        creditLimit: creditLimit,
        billingCycleDay: billingCycleDay,
      );
      await loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteAccount(String accountId) async {
    try {
      await _repository.deleteAccount(accountId);
      await loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final accountsNotifierProvider = StateNotifierProvider<AccountsNotifier, AccountsState>((ref) {
  return AccountsNotifier(repository: ref.watch(accountsRepositoryProvider));
});
