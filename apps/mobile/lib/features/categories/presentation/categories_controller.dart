import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/categories_repository.dart';
import '../domain/category_entity.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository();
});

class CategoriesState {
  final bool isLoading;
  final List<CategoryEntity> categories;
  final String? errorMessage;

  const CategoriesState({
    this.isLoading = false,
    this.categories = const [],
    this.errorMessage,
  });

  CategoriesState copyWith({
    bool? isLoading,
    List<CategoryEntity>? categories,
    String? errorMessage,
  }) {
    return CategoriesState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
    );
  }
}

class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final CategoriesRepository _repository;

  CategoriesNotifier({required CategoriesRepository repository})
      : _repository = repository,
        super(const CategoriesState()) {
    loadCategories();
  }

  Future<void> loadCategories({CategoryType? type}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final categories = await _repository.getCategories(type: type);
      state = state.copyWith(isLoading: false, categories: categories);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createCategory({
    required String name,
    required String icon,
    required String colorHex,
    required CategoryType type,
    String? parentId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createCustomCategory(
        name: name,
        icon: icon,
        colorHex: colorHex,
        type: type,
        parentId: parentId,
      );
      await loadCategories();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _repository.deleteCategory(categoryId);
      await loadCategories();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final categoriesNotifierProvider = StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
  return CategoriesNotifier(repository: ref.watch(categoriesRepositoryProvider));
});
