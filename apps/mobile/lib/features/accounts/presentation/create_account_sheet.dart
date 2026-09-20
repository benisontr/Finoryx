import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/account_entity.dart';
import 'accounts_controller.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

class CreateAccountSheet extends ConsumerStatefulWidget {
  const CreateAccountSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateAccountSheet(),
    );
  }

  @override
  ConsumerState<CreateAccountSheet> createState() => _CreateAccountSheetState();
}

class _CreateAccountSheetState extends ConsumerState<CreateAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.00');
  final _creditLimitController = TextEditingController();
  AccountType _selectedType = AccountType.bank;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final initialBal = double.tryParse(_balanceController.text) ?? 0.0;
    final creditLimit = _selectedType == AccountType.creditCard
        ? double.tryParse(_creditLimitController.text)
        : null;

    final success = await ref.read(accountsNotifierProvider.notifier).createAccount(
          name: _nameController.text.trim(),
          accountType: _selectedType,
          initialBalance: initialBal,
          creditLimit: creditLimit,
        );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Add Financial Account',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Type Selector
            DropdownButtonFormField<AccountType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Account Type',
                prefixIcon: Icon(_selectedType.iconData),
              ),
              items: AccountType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.iconData, size: 18, color: type.color),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 16),

            // Account Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name (e.g. HDFC Salary)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Please enter account name' : null,
            ),
            const SizedBox(height: 16),

            // Initial Balance
            TextFormField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _selectedType == AccountType.creditCard
                    ? 'Current Outstanding Balance'
                    : 'Initial Balance',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
              validator: (val) =>
                  (val == null || double.tryParse(val) == null) ? 'Enter a valid amount' : null,
            ),
            const SizedBox(height: 16),

            // Credit Limit (if Credit Card)
            if (_selectedType == AccountType.creditCard) ...[
              TextFormField(
                controller: _creditLimitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Credit Limit (Optional)',
                  prefixIcon: Icon(Icons.credit_card),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _handleSave,
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
