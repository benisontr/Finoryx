import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'budgets_controller.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../categories/domain/category_entity.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';

class CreateBudgetSheet extends ConsumerStatefulWidget {
  const CreateBudgetSheet({super.key});

  @override
  ConsumerState<CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends ConsumerState<CreateBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  String? _selectedCategoryId;
  double _notifyThreshold = 80;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final limit = double.tryParse(_limitController.text.trim()) ?? 0.0;

    final success = await ref.read(budgetsNotifierProvider.notifier).createBudget(
          categoryId: _selectedCategoryId!,
          limitAmount: limit,
          notifyThresholdPct: _notifyThreshold.toInt(),
        );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category budget created successfully!'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesNotifierProvider);
    final currencySymbol = ref.watch(userCurrencySymbolProvider);
    final expenseCategories = categoriesState.categories
        .where((c) => c.type == CategoryType.expense)
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Set Category Spending Budget',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Category Selector
              const Text('Select Expense Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              if (expenseCategories.isEmpty)
                const Text('No categories found', style: TextStyle(color: Colors.grey))
              else
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: expenseCategories.length,
                    itemBuilder: (context, index) {
                      final cat = expenseCategories[index];
                      final isSelected = cat.id == _selectedCategoryId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: Icon(cat.iconData, size: 16, color: isSelected ? Colors.white : cat.color),
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategoryId = selected ? cat.id : null);
                          },
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 18),

              // Monthly Limit Input
              TextFormField(
                controller: _limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Monthly Spending Cap ($currencySymbol)',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter a budget limit';
                  final num = double.tryParse(val);
                  if (num == null || num <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Alert Threshold Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pace Warning Threshold', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${_notifyThreshold.toInt()}% of budget', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              Slider(
                value: _notifyThreshold,
                min: 50,
                max: 100,
                divisions: 10,
                label: '${_notifyThreshold.toInt()}%',
                onChanged: (val) => setState(() => _notifyThreshold = val),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _handleSave,
                child: const Text('Save Category Budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
