import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/account_entity.dart';
import 'accounts_controller.dart';
import 'create_account_sheet.dart';
import '../../transactions/presentation/quick_add_transaction_sheet.dart';
import '../../transactions/domain/transaction_entity.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/finoryx_card.dart';
import '../../../core/widgets/finoryx_empty_state.dart';
import '../../../core/widgets/finoryx_section_header.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountsNotifierProvider);
    final currencySymbol = ref.watch(userCurrencySymbolProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'Accounts & Ledger',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(accountsNotifierProvider.notifier).loadAccounts(),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'accounts_fab',
        onPressed: () => CreateAccountSheet.show(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
      ),
      body: state.isLoading && state.accounts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(accountsNotifierProvider.notifier).loadAccounts(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                children: [
                  // Net Financial Assets Overview Card
                  if (state.summary != null)
                    _buildSummaryCard(state.summary!, isDark, currencySymbol),
                  const SizedBox(height: AppSpacing.md),

                  // Accounts List
                  if (state.accounts.isEmpty)
                    FinoryxEmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No Accounts Connected',
                      subtitle: 'Add checking, savings, investment, or credit accounts to start tracking balances.',
                      actionLabel: 'Add Your First Account',
                      onAction: () => CreateAccountSheet.show(context),
                    )
                  else ...[
                    const FinoryxSectionHeader(title: 'Your Accounts'),
                    ...state.accounts.map((acc) => _buildAccountItem(context, acc, isDark, currencySymbol)),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(AccountsSummaryEntity summary, bool isDark, String currencySymbol) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
              : [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NET FINANCIAL ASSETS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.currency(summary.totalNetWorth, symbol: currencySymbol),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Liquid Assets', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.currency(summary.totalAssets, symbol: currencySymbol),
                        style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                Container(height: 20, width: 1, color: Colors.white24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Liabilities / Owed', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.currency(summary.totalLiabilities, symbol: currencySymbol),
                        style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(
    BuildContext context,
    AccountEntity account,
    bool isDark,
    String currencySymbol,
  ) {
    final isLiability = account.accountType == AccountType.creditCard;
    final isNegative = account.currentBalance < 0;

    IconData accIcon;
    Color iconColor;
    Color iconBg;

    switch (account.accountType) {
      case AccountType.bank:
        accIcon = Icons.account_balance_outlined;
        iconColor = const Color(0xFF3B82F6);
        iconBg = const Color(0xFFDBEAFE);
        break;
      case AccountType.creditCard:
        accIcon = Icons.credit_card_rounded;
        iconColor = const Color(0xFFEF4444);
        iconBg = const Color(0xFFFEE2E2);
        break;
      case AccountType.digitalWallet:
        accIcon = Icons.phone_android_rounded;
        iconColor = const Color(0xFF8B5CF6);
        iconBg = const Color(0xFFEDE9FE);
        break;
      case AccountType.cash:
        accIcon = Icons.money_rounded;
        iconColor = const Color(0xFF10B981);
        iconBg = const Color(0xFFD1FAE5);
        break;
      case AccountType.other:
        accIcon = Icons.wallet_outlined;
        iconColor = const Color(0xFF64748B);
        iconBg = const Color(0xFFF1F5F9);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FinoryxCard(
        onTap: () {
          QuickAddTransactionSheet.show(
            context,
            initialType: isLiability ? TransactionType.expense : TransactionType.transfer,
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isDark ? iconColor.withValues(alpha: 0.2) : iconBg,
              child: Icon(accIcon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.accountType.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.currency(account.currentBalance, symbol: currencySymbol),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isNegative || isLiability
                        ? (isDark ? const Color(0xFFF87171) : AppColors.expense)
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLiability ? 'Balance Owed' : 'Available',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
