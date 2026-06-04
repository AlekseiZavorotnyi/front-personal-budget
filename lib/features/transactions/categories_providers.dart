import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_personal_budget/features/transactions/transactions_providers.dart';
import '../../core/providers/api_providers.dart';
import '../../core/models/category_model.dart';

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final api = ref.watch(apiClientProvider);

  final response = await api.dio.get('/api/categories');
  final items = response.data['items'] as List;

  return items.map((e) => CategoryModel.fromJson(e)).toList();
});


final addCategoryProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);

  Future<void> addCategory(String name) async {
    await api.dio.post('/api/categories', data: {
      "name": name,
      "type": "expense",
    });

    ref.invalidate(categoriesProvider);
    ref.invalidate(transactionsProvider);
  }

  return addCategory;
});

final updateCategoryProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);

  Future<void> updateCategory({
    required String id,
    required String name,
  }) async {
    await api.dio.patch('/api/categories/$id', data: {
      "name": name,
      "type": null,
    });

    ref.invalidate(categoriesProvider);
    ref.invalidate(transactionsProvider);
  }

  return updateCategory;
});


final deleteCategoryProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);

  Future<void> deleteCategory(String id) async {
    await api.dio.delete('/api/categories/$id');

    ref.invalidate(categoriesProvider);
  }

  return deleteCategory;
});

final categorySearchProvider = StateProvider<String>((ref) => "");

final filteredCategoriesProvider = Provider((ref) {
  final search = ref.watch(categorySearchProvider).toLowerCase();
  final categories = ref.watch(categoriesProvider).value ?? [];

  if (search.isEmpty) return categories;

  return categories
      .where((c) => c.name.toLowerCase().contains(search))
      .toList();
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
