import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/transaction_entity.dart';
import 'transactions_controller.dart';
import 'quick_add_transaction_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/finoryx_card.dart';
import '../../../core/widgets/finoryx_empty_state.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends ConsumerState<TransactionsListScreen> {
  TransactionType? _selectedFilter;

  Future<void> _confirmDelete(TransactionEntity tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete this ${tx.type.displayName} of ${tx.amount}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(transactionsNotifierProvider.notifier).deleteTransaction(tx.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted & balance adjusted!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsNotifierProvider);
    final currencySymbol = ref.watch(userCurrencySymbolProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _selectedFilter == null
        ? state.transactions
        : state.transactions.where((t) => t.type == _selectedFilter).toList();

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
          'Transactions',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(transactionsNotifierProvider.notifier).loadTransactions(),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'transactions_fab',
        onPressed: () => QuickAddTransactionSheet.show(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Record Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All (${state.transactions.length})', _selectedFilter == null, () {
                    setState(() => _selectedFilter = null);
                  }, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Expenses', _selectedFilter == TransactionType.expense, () {
                    setState(() => _selectedFilter = TransactionType.expense);
                  }, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Income', _selectedFilter == TransactionType.income, () {
                    setState(() => _selectedFilter = TransactionType.income);
                  }, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Transfers', _selectedFilter == TransactionType.transfer, () {
                    setState(() => _selectedFilter = TransactionType.transfer);
                  }, isDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          Expanded(
            child: state.isLoading && state.transactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ref.read(transactionsNotifierProvider.notifier).loadTransactions(),
                    child: filteredList.isEmpty
                        ? FinoryxEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No Transactions Found',
                            subtitle: 'Record expenses, income, or account transfers to maintain your live ledger.',
                            actionLabel: 'Record First Entry',
                            onAction: () => QuickAddTransactionSheet.show(context),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final tx = filteredList[index];
                              return _buildTransactionItem(context, tx, isDark, currencySymbol);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionEntity tx,
    bool isDark,
    String currencySymbol,
  ) {
    final isIncome = tx.type == TransactionType.income;
    final isTransfer = tx.type == TransactionType.transfer;

    Color iconColor = isIncome ? AppColors.income : (isTransfer ? AppColors.info : AppColors.expense);
    Color iconBg = isIncome ? AppColors.incomeContainer : (isTransfer ? AppColors.infoContainer : AppColors.expenseContainer);
    IconData iconData = isIncome ? Icons.arrow_downward_rounded : (isTransfer ? Icons.sync_alt_rounded : Icons.arrow_upward_rounded);

    final desc = (tx.description != null && tx.description!.isNotEmpty)
        ? tx.description!
        : (tx.categoryName ?? tx.type.displayName);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FinoryxCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: iconBg,
              child: Icon(iconData, color: iconColor, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    desc,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(tx.transactionDate),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      if (tx.accountName != null) ...[
                        Text(' • ', style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                        Text(
                          tx.accountName!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : (isTransfer ? '' : '-')}${AppFormatters.currency(tx.amount, symbol: currencySymbol)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: isIncome
                        ? AppColors.income
                        : (isTransfer ? AppColors.info : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'delete') _confirmDelete(tx);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: AppColors.expense),
                          SizedBox(width: 8),
                          Text('Delete Entry', style: TextStyle(color: AppColors.expense)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
