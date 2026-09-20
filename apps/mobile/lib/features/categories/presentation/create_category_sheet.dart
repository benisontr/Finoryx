import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/category_entity.dart';
import 'categories_controller.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

class CreateCategorySheet extends ConsumerStatefulWidget {
  const CreateCategorySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateCategorySheet(),
    );
  }

  @override
  ConsumerState<CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends ConsumerState<CreateCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  CategoryType _type = CategoryType.expense;
  String _selectedIcon = 'local_cafe';
  String _selectedColor = '#6366F1';

  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'local_cafe', 'icon': Icons.local_cafe},
    {'name': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart},
    {'name': 'directions_car', 'icon': Icons.directions_car},
    {'name': 'home', 'icon': Icons.home},
    {'name': 'bolt', 'icon': Icons.bolt},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag},
    {'name': 'movie', 'icon': Icons.movie},
    {'name': 'medical_services', 'icon': Icons.medical_services},
    {'name': 'school', 'icon': Icons.school},
    {'name': 'flight', 'icon': Icons.flight},
    {'name': 'payments', 'icon': Icons.payments},
    {'name': 'laptop', 'icon': Icons.laptop},
    {'name': 'trending_up', 'icon': Icons.trending_up},
  ];

  final List<String> _colorOptions = [
    '#EF4444',
    '#F97316',
    '#F59E0B',
    '#10B981',
    '#06B6D4',
    '#3B82F6',
    '#6366F1',
    '#8B5CF6',
    '#EC4899',
    '#6B7280',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(categoriesNotifierProvider.notifier).createCategory(
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          colorHex: _selectedColor,
          type: _type,
        );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'New Custom Category',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segmented Type: Expense vs Income
            SegmentedButton<CategoryType>(
              segments: const [
                ButtonSegment(value: CategoryType.expense, label: Text('Expense')),
                ButtonSegment(value: CategoryType.income, label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
            const SizedBox(height: 20),

            // Category Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name (e.g. Subscriptions)',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Please enter category name' : null,
            ),
            const SizedBox(height: 20),

            // Icon Picker
            const Text('Choose Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _iconOptions.length,
                itemBuilder: (context, index) {
                  final item = _iconOptions[index];
                  final isSelected = item['name'] == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = item['name']),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        item['icon'],
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade700,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Color Picker
            const Text('Choose Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colorOptions.length,
                itemBuilder: (context, index) {
                  final hex = _colorOptions[index];
                  final isSelected = hex == _selectedColor;
                  final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _handleSave,
              child: const Text('Create Category'),
            ),
          ],
        ),
      ),
    );
  }
}
