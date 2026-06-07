import 'package:hive/hive.dart';
import '../../core/services/local_budget_cache.dart';

class CacheService {
  static const _boxesToClear = [
    LocalBudgetCache.offlineTransactionsBoxName,
    LocalBudgetCache.cachedTransactionsBoxName,
    LocalBudgetCache.offlineCategoriesBoxName,
    LocalBudgetCache.cachedCategoriesBoxName,
  ];

  static Future<void> clearAllCache() async {
    try {
      for (final boxName in _boxesToClear) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
        } else {
          final box = await Hive.openBox(boxName);
          await box.clear();
          await box.close();
        }
      }
      print('All cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  static Future<void> closeAllBoxes() async {
    try {
      for (final boxName in _boxesToClear) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.close();
        }
      }
      print('All boxes closed successfully');
    } catch (e) {
      print('Error closing boxes: $e');
    }
  }

  static Future<bool> hasCachedData() async {
    try {
      final transactionsBox = await Hive.openBox(LocalBudgetCache.cachedTransactionsBoxName);
      final categoriesBox = await Hive.openBox(LocalBudgetCache.cachedCategoriesBoxName);

      final hasTransactions = transactionsBox.isNotEmpty;
      final hasCategories = categoriesBox.isNotEmpty;

      await transactionsBox.close();
      await categoriesBox.close();

      return hasTransactions || hasCategories;
    } catch (e) {
      return false;
    }
  }
}