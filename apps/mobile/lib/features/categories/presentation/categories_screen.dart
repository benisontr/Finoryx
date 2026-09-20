import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/category_entity.dart';
import 'categories_controller.dart';
import 'create_category_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/finoryx_card.dart';
import '../../../core/widgets/finoryx_empty_state.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final expenseCategories = state.categories.where((c) => c.type == CategoryType.expense).toList();
    final incomeCategories = state.categories.where((c) => c.type == CategoryType.income).toList();

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
          'Categories & Taxonomies',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: [
            Tab(text: 'Expense (${expenseCategories.length})'),
            Tab(text: 'Income (${incomeCategories.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'categories_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateCategorySheet(),
          );
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
      ),
      body: state.isLoading && state.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryGrid(expenseCategories, isDark),
                _buildCategoryGrid(incomeCategories, isDark),
              ],
            ),
    );
  }

  Widget _buildCategoryGrid(List<CategoryEntity> list, bool isDark) {
    if (list.isEmpty) {
      return FinoryxEmptyState(
        icon: Icons.category_outlined,
        title: 'No Categories Found',
        subtitle: 'Create custom categories to organize your transactions with colors and icons.',
        actionLabel: 'Create Category',
        onAction: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateCategorySheet(),
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.2,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final cat = list[index];
        return FinoryxCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: cat.color.withValues(alpha: isDark ? 0.2 : 0.12),
                child: Icon(cat.iconData, color: cat.color, size: 18),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cat.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (cat.isSystem)
                      Text(
                        'System',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
