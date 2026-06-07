import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_personal_budget/features/transactions/transactions_providers.dart';
import '../../core/providers/api_providers.dart';
import '../../core/models/category_model.dart';
import '../../core/services/local_budget_cache.dart';

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final api = ref.watch(apiClientProvider);

  try {
    final response = await api.dio.get('/api/categories');
    final items = response.data['items'] as List;
    await LocalBudgetCache.cacheCategories(items);

    return items.map((e) => CategoryModel.fromJson(e)).toList();
  } catch (_) {
    return _readLocalCategoriesSafely();
  }
});

Future<List<CategoryModel>> _readLocalCategoriesSafely() async {
  try {
    return await LocalBudgetCache.readCachedCategories();
  } catch (_) {
    return [];
  }
}

final addCategoryProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);

  Future<void> addCategory(String name) async {
    try {
      final response = await api.dio.post('/api/categories', data: {
        "name": name,
        "type": "expense",
      });

      await LocalBudgetCache.upsertCategory(response.data);
    } on DioException catch (error) {
      if (error.response != null) rethrow;

      final localId = "local-${DateTime.now().millisecondsSinceEpoch}";

      await LocalBudgetCache.putOfflineCategory({
        "id": localId,
        "name": name,
        "operation": "create",
      });
    }

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
    try {
      final response = await api.dio.patch('/api/categories/$id', data: {
        "name": name,
        "type": "expense",
      });

      await LocalBudgetCache.upsertCategory(response.data);
      await LocalBudgetCache.updateCategoryNameInTransactions(
        categoryId: id,
        newName: name,
      );
    } on DioException catch (error) {
      if (error.response != null) rethrow;

      await LocalBudgetCache.putOfflineCategory({
        "id": id,
        "name": name,
        "operation": "update",
      });

      await LocalBudgetCache.updateCategoryNameInTransactions(
        categoryId: id,
        newName: name,
      );
    }

    ref.invalidate(categoriesProvider);
    ref.invalidate(transactionsProvider);
  }

  return updateCategory;
});

final deleteCategoryProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);

  Future<void> deleteCategory(String id) async {
    try {
      await api.dio.delete('/api/categories/$id');
      await LocalBudgetCache.removeCategory(id);
    } on DioException catch (error) {
      if (error.response != null) rethrow;

      await LocalBudgetCache.deleteOfflineCategory(id);
    }

    ref.invalidate(categoriesProvider);
    ref.invalidate(transactionsProvider);
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