import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/transaction_entity.dart';
import 'transactions_controller.dart';
import '../../accounts/presentation/accounts_controller.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/finoryx_button.dart';

class QuickAddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionType initialType;

  const QuickAddTransactionSheet({
    super.key,
    this.initialType = TransactionType.expense,
  });

  static void show(BuildContext context, {TransactionType initialType = TransactionType.expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddTransactionSheet(initialType: initialType),
    );
  }

  @override
  ConsumerState<QuickAddTransactionSheet> createState() => _QuickAddTransactionSheetState();
}

class _QuickAddTransactionSheetState extends ConsumerState<QuickAddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late TransactionType _type;
  String? _selectedAccountId;
  String? _selectedDestAccountId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addPresetAmount(double increment) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final updated = current + increment;
    _amountController.text = updated.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    if (_type == TransactionType.transfer && _selectedDestAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination account')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final success = await ref.read(transactionsNotifierProvider.notifier).recordTransaction(
          accountId: _selectedAccountId!,
          destinationAccountId: _selectedDestAccountId,
          categoryId: _selectedCategoryId,
          type: _type,
          amount: amount,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );

    if (success && mounted) {
      final currencySymbol = ref.read(userCurrencySymbolProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_type.displayName} of ${AppFormatters.currency(amount, symbol: currencySymbol)} recorded!'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountsState = ref.watch(accountsNotifierProvider);
    final categoriesState = ref.watch(categoriesNotifierProvider);
    final currencySymbol = ref.watch(userCurrencySymbolProvider);

    final filteredCategories = categoriesState.categories.where((c) {
      if (_type == TransactionType.expense) return c.type.name.toLowerCase() == 'expense';
      if (_type == TransactionType.income) return c.type.name.toLowerCase() == 'income';
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title & Close Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Record Transaction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Type Selector Segmented Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    _buildTypeTab(TransactionType.expense, 'Expense', AppColors.expense, isDark),
                    _buildTypeTab(TransactionType.income, 'Income', AppColors.income, isDark),
                    _buildTypeTab(TransactionType.transfer, 'Transfer', AppColors.info, isDark),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Hero Numeric Amount Field
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _type == TransactionType.income
                      ? AppColors.income
                      : (_type == TransactionType.transfer
                          ? AppColors.info
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                ),
                decoration: InputDecoration(
                  prefixText: '$currencySymbol ',
                  prefixStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  hintText: '0.00',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter an amount';
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs),

              // Quick Amount Preset Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPresetChip('+500', 500, isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildPresetChip('+1,000', 1000, isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildPresetChip('+2,000', 2000, isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildPresetChip('+5,000', 5000, isDark),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Source Account Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                decoration: InputDecoration(
                  labelText: _type == TransactionType.transfer ? 'Source Account' : 'Account',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                ),
                items: accountsState.accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text('${acc.name} ($currencySymbol${acc.currentBalance.toStringAsFixed(2)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                validator: (val) => val == null ? 'Please select an account' : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Destination Account Selector (Transfer only)
              if (_type == TransactionType.transfer) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedDestAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Destination Account',
                    prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
                  ),
                  items: accountsState.accounts
                      .where((acc) => acc.id != _selectedAccountId)
                      .map((acc) {
                    return DropdownMenuItem(
                      value: acc.id,
                      child: Text('${acc.name} ($currencySymbol${acc.currentBalance.toStringAsFixed(2)})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDestAccountId = val),
                  validator: (val) => val == null ? 'Please select destination account' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Category Selector (Expense & Income)
              if (_type != TransactionType.transfer) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                  ),
                  items: filteredCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Row(
                        children: [
                          Icon(cat.iconData, size: 18, color: cat.color),
                          const SizedBox(width: 8),
                          Text(cat.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Note / Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Note / Memo (Optional)',
                  prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Submit CTA Button
              FinoryxButton(
                text: _type == TransactionType.transfer
                    ? 'Transfer Funds'
                    : (_type == TransactionType.income ? 'Save Income' : 'Save Expense'),
                icon: Icons.check_circle_outline_rounded,
                variant: FinoryxButtonVariant.primary,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(TransactionType type, String label, Color color, bool isDark) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _selectedCategoryId = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double amount, bool isDark) {
    return GestureDetector(
      onTap: () => _addPresetAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}
