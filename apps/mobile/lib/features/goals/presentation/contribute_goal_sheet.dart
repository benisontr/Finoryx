import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'goals_controller.dart';
import '../domain/goal_entity.dart';
import '../../accounts/presentation/accounts_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';

class ContributeGoalSheet extends ConsumerStatefulWidget {
  final GoalEntity goal;

  const ContributeGoalSheet({super.key, required this.goal});

  @override
  ConsumerState<ContributeGoalSheet> createState() => _ContributeGoalSheetState();
}

class _ContributeGoalSheetState extends ConsumerState<ContributeGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedSourceAccountId;

  @override
  void initState() {
    super.initState();
    // Default to linked account if one exists
    _selectedSourceAccountId = widget.goal.linkedAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleContribute() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final success = await ref.read(goalsControllerProvider.notifier).contribute(
          id: widget.goal.id,
          amount: amount,
          sourceAccountId: _selectedSourceAccountId,
        );

    if (success && mounted) {
      final currencySymbol = ref.read(userCurrencySymbolProvider);
      // Reload accounts so updated balances reflect immediately
      ref.read(accountsNotifierProvider.notifier).loadAccounts();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${AppFormatters.currency(amount, symbol: currencySymbol)} to ${widget.goal.name}!'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = ref.watch(accountsNotifierProvider).accounts;
    final currencySymbol = ref.watch(userCurrencySymbolProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Contribution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      widget.goal.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contribution Amount
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Contribution Amount ($currencySymbol)',
                hintText: 'e.g. 5000.00',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter contribution amount';
                }
                final parsed = double.tryParse(val.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Please enter a valid positive amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Source Account Selector (Optional)
            if (accounts.isNotEmpty)
              DropdownButtonFormField<String?>(
                initialValue: _selectedSourceAccountId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Deduct From Account (Optional)',
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'External Deposit (No balance deduction)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...accounts.map(
                    (acc) => DropdownMenuItem<String?>(
                      value: acc.id,
                      child: Text(
                        '${acc.name} (${AppFormatters.currency(acc.currentBalance, symbol: AppFormatters.symbolForCurrency(acc.currency))})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedSourceAccountId = val;
                  });
                },
              ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _handleContribute,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Confirm Contribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
