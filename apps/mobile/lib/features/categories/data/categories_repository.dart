import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/category_entity.dart';

class CategoriesRepository {
  final ApiClient _apiClient;

  CategoriesRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<CategoryEntity>> getCategories({CategoryType? type}) async {
    try {
      final response = await _apiClient.dio.get(
        '/categories',
        queryParameters: type != null ? {'type': type.toApiString()} : null,
      );
      final List data = ApiClient.extractData(response) ?? [];
      return data.map((json) => CategoryEntity.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to fetch categories');
    }
  }

  Future<CategoryEntity> createCustomCategory({
    required String name,
    required String icon,
    required String colorHex,
    required CategoryType type,
    String? parentId,
  }) async {
    try {
      final response = await _apiClient.dio.post('/categories', data: {
        'name': name,
        'icon': icon,
        'colorHex': colorHex,
        'type': type.toApiString(),
        'parentId': parentId,
      });

      final data = ApiClient.extractData(response);
      return CategoryEntity.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to create category');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _apiClient.dio.delete('/categories/$categoryId');
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e, 'Failed to delete category');
    }
  }
}
