import 'package:hive/hive.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';

class LocalBudgetCache {
  static const offlineTransactionsBoxName = 'offline_transactions';
  static const cachedTransactionsBoxName = 'cached_transactions';
  static const offlineCategoriesBoxName = 'offline_categories';
  static const cachedCategoriesBoxName = 'cached_categories';

  static Future<void> initialize() async {
    await Future.wait([
      Hive.openBox(offlineTransactionsBoxName),
      Hive.openBox(offlineCategoriesBoxName),
      Hive.openBox(cachedTransactionsBoxName),
      Hive.openBox(cachedCategoriesBoxName),
    ]);
  }

  static Future<void> cacheServerTransactions(
    List<dynamic> items, {
    bool replace = false,
  }) async {
    final transactionsBox = await Hive.openBox(cachedTransactionsBoxName);
    final categoriesBox = await Hive.openBox(cachedCategoriesBoxName);

    if (replace) {
      await transactionsBox.clear();
    }

    for (final item in items) {
      final json = normalizeTransactionJson(item, defaultSyncStatus: 'synced');
      await transactionsBox.put(json['id'], json);
      await _cacheCategoryFromTransaction(categoriesBox, json);
    }
  }

  static Future<void> upsertServerTransaction(dynamic item) async {
    final json = normalizeTransactionJson(item, defaultSyncStatus: 'synced');
    final transactionsBox = await Hive.openBox(cachedTransactionsBoxName);
    final categoriesBox = await Hive.openBox(cachedCategoriesBoxName);

    await transactionsBox.put(json['id'], json);
    await _cacheCategoryFromTransaction(categoriesBox, json);
  }

  static Future<void> removeCachedTransaction(String id) async {
    final box = await Hive.openBox(cachedTransactionsBoxName);
    await box.delete(id);
  }

  static Future<List<TransactionModel>> readCachedTransactions() async {
    final box = await Hive.openBox(cachedTransactionsBoxName);
    return box.values
        .map((item) => normalizeTransactionJson(item))
        .map(TransactionModel.fromJson)
        .toList();
  }

  static Future<List<TransactionModel>> readOfflineTransactions() async {
    final box = await Hive.openBox(offlineTransactionsBoxName);
    return box.values
        .map((item) => normalizeTransactionJson(
              item,
              defaultSyncStatus: 'pending',
            ))
        .map(TransactionModel.fromJson)
        .toList();
  }

  static Future<List<TransactionModel>> readAllTransactions() async {
    return [
      ...await readOfflineTransactions(),
      ...await readCachedTransactions(),
    ];
  }

  static Future<void> putOfflineTransaction(
    String localId,
    Map<String, dynamic> transaction,
  ) async {
    final box = await Hive.openBox(offlineTransactionsBoxName);
    final categoriesBox = await Hive.openBox(cachedCategoriesBoxName);
    final json = normalizeTransactionJson({
      ...transaction,
      'id': localId,
      'localId': localId,
      'syncStatus': 'pending',
    });
    await box.put(localId, json);
    await _cacheCategoryFromTransaction(categoriesBox, json);
  }

  static Future<bool> hasOfflineTransaction(String id) async {
    final box = await Hive.openBox(offlineTransactionsBoxName);
    return box.containsKey(id);
  }

  static Future<bool> isPendingOfflineCreate(String id) async {
    final box = await Hive.openBox(offlineTransactionsBoxName);
    final raw = box.get(id);
    if (raw is! Map) {
      return false;
    }

    return raw['isUpdate'] != true;
  }

  static Future<void> updateOfflineTransaction(
    String id,
    Map<String, dynamic> transaction,
  ) async {
    final box = await Hive.openBox(offlineTransactionsBoxName);
    if (!box.containsKey(id)) {
      return;
    }

    final current = normalizeTransactionJson(
      box.get(id),
      defaultSyncStatus: 'pending',
    );
    final updated = normalizeTransactionJson({
      ...current,
      ...transaction,
      'categoryId': transaction['categoryId'] ?? current['categoryId'] ?? '',
      'categoryName': transaction['categoryName'] ?? current['categoryName'] ?? '',
      'title': transaction['comment'] ?? current['title'] ?? '',
      'description': transaction['comment'] ?? current['description'] ?? '',
      'comment': transaction['comment'] ?? current['comment'] ?? '',
      'id': id,
      'localId': current['localId'] ?? id,
      'syncStatus': 'pending',
    });

    await box.put(id, updated);
    await _cacheCategoryFromTransaction(
      await Hive.openBox(cachedCategoriesBoxName),
      updated,
    );
  }

  static Future<void> deleteOfflineTransaction(String id) async {
    final box = await Hive.openBox(offlineTransactionsBoxName);
    await box.delete(id);
  }

  static Future<List<Map<String, dynamic>>>
  readOfflineTransactionPayloads() async {
    final box = await Hive.openBox(offlineTransactionsBoxName);
    return box.values.map((item) {
      final json = normalizeTransactionJson(
        item,
        defaultSyncStatus: 'pending',
      );
      final originalId = json['originalId'] ?? json['id'];
      final originalCategoryId = json['originalCategoryId'] ?? json['categoryId'];
      final isUpdate = json['isUpdate'] == true;

      return {
        'localId': json['localId'] ?? json['id'],
        'type': json['type'],
        'amount': json['amount'],
        'categoryId': isUpdate ? originalCategoryId : (_isUuid(json['categoryId']) ? json['categoryId'] : null),
        'date': json['date'],
        'title': json['title'] ?? json['comment'],
        'description': json['description'] ?? json['comment'],
        'comment': json['comment'],
        if (isUpdate) 'id': originalId,
        'isUpdate': isUpdate,
      };
    }).toList();
  }

  static Future<void> cacheCategories(List<dynamic> items) async {
    final box = await Hive.openBox(cachedCategoriesBoxName);
    await box.clear();

    for (final item in items) {
      final json = normalizeCategoryJson(item);
      if ((json['id'] as String).isEmpty) {
        continue;
      }
      await box.put(json['id'], json);
    }
  }

  static Future<void> upsertCategory(dynamic item) async {
    final box = await Hive.openBox(cachedCategoriesBoxName);
    final json = normalizeCategoryJson(item);
    if ((json['id'] as String).isEmpty) {
      return;
    }

    await box.put(json['id'], json);
  }

  static Future<void> removeCategory(String id) async {
    final box = await Hive.openBox(cachedCategoriesBoxName);
    await box.delete(id);
  }

  static Future<void> remapCategoryId({
    required String oldId,
    required String newId,
    String? newName,
  }) async {
    if (oldId == newId) {
      return;
    }

    final cachedTx = await Hive.openBox(cachedTransactionsBoxName);
    final offlineTx = await Hive.openBox(offlineTransactionsBoxName);

    for (final box in [cachedTx, offlineTx]) {
      for (final key in box.keys.toList()) {
        final raw = box.get(key);
        if (raw is! Map) {
          continue;
        }

        final item = raw.map((k, v) => MapEntry(k.toString(), v));
        var changed = false;

        if (item['categoryId'] == oldId) {
          item['categoryId'] = newId;
          if (newName != null) {
            item['categoryName'] = newName;
          }
          changed = true;
        }

        if (item['originalCategoryId'] == oldId) {
          item['originalCategoryId'] = newId;
          changed = true;
        }

        if (changed) {
          await box.put(key, item);
        }
      }
    }

    final cachedCategories = await Hive.openBox(cachedCategoriesBoxName);
    await cachedCategories.delete(oldId);
    if (newName != null) {
      await cachedCategories.put(newId, {'id': newId, 'name': newName});
    }
  }

  static Future<List<CategoryModel>> readCachedCategories() async {
    final categoriesBox = await Hive.openBox(cachedCategoriesBoxName);
    final transactionsBox = await Hive.openBox(cachedTransactionsBoxName);
    final offlineBox = await Hive.openBox(offlineTransactionsBoxName);
    final byId = <String, Map<String, dynamic>>{};

    for (final item in categoriesBox.values) {
      final category = normalizeCategoryJson(item);
      final id = category['id'] as String;
      if (id.isNotEmpty) {
        byId[id] = category;
      }
    }

    for (final item in [...transactionsBox.values, ...offlineBox.values]) {
      final transaction = normalizeTransactionJson(item);
      final category = _categoryFromTransaction(transaction);
      if (category == null) {
        continue;
      }

      byId.putIfAbsent(category['id'] as String, () => category);
    }

    final categories = byId.values.map(CategoryModel.fromJson).toList();
    categories.sort((a, b) => a.name.compareTo(b.name));

    return categories;
  }

  static Future<void> putOfflineCategory(Map<String, dynamic> json) async {
    final box = await Hive.openBox(offlineCategoriesBoxName);
    await box.put(json['id'], {
      ...json,
      'syncStatus': 'pending',
    });

    final cached = await Hive.openBox(cachedCategoriesBoxName);
    await cached.put(json['id'], {
      'id': json['id'],
      'name': json['name'],
    });
  }

  static Future<void> deleteOfflineCategory(String id) async {
    final offline = await Hive.openBox(offlineCategoriesBoxName);
    final cached = await Hive.openBox(cachedCategoriesBoxName);

    await offline.put(id, {
      'id': id,
      'operation': 'delete',
      'syncStatus': 'pending',
    });

    await cached.delete(id);
  }

  static Future<List<Map<String, dynamic>>> readOfflineCategories() async {
    final box = await Hive.openBox(offlineCategoriesBoxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> removeOfflineCategory(String id) async {
    final box = await Hive.openBox(offlineCategoriesBoxName);
    await box.delete(id);
  }

  static Future<void> updateCategoryNameInTransactions({
    required String categoryId,
    required String newName,
  }) async {
    final cached = await Hive.openBox(cachedTransactionsBoxName);
    final offline = await Hive.openBox(offlineTransactionsBoxName);

    for (final key in cached.keys) {
      final item = normalizeTransactionJson(cached.get(key));
      if (item['categoryId'] == categoryId) {
        await cached.put(key, {
          ...item,
          'categoryName': newName,
        });
      }
    }

    for (final key in offline.keys) {
      final item = normalizeTransactionJson(offline.get(key));
      if (item['categoryId'] == categoryId) {
        await offline.put(key, {
          ...item,
          'categoryName': newName,
        });
      }
    }
  }

  static Future<void> updateCachedTransactionComment(
      String id,
      String newComment,
      ) async {
    final box = await Hive.openBox(cachedTransactionsBoxName);
    if (!box.containsKey(id)) return;

    final current = normalizeTransactionJson(box.get(id));
    final updated = {
      ...current,
      'comment': newComment,
      'title': newComment,
      'description': newComment,
    };

    await box.put(id, updated);
  }

  static Future<List<TransactionModel>> readAllTransactionsUnique() async {
    final offline = await readOfflineTransactions();
    final cached = await readCachedTransactions();

    final Map<String, TransactionModel> unique = {};

    for (final t in offline) {
      unique[t.id] = t;
    }

    for (final t in cached) {
      if (!unique.containsKey(t.id)) {
        unique[t.id] = t;
      }
    }

    return unique.values.toList();
  }

  static Future<String?> categoryNameById(String? id) async {
    if (id == null) {
      return null;
    }

    final box = await Hive.openBox(cachedCategoriesBoxName);
    final item = box.get(id);
    if (item == null) {
      return null;
    }

    return normalizeCategoryJson(item)['name'];
  }

  static Map<String, dynamic> normalizeTransactionJson(
      dynamic item, {
        String defaultSyncStatus = 'synced',
      }) {
    final json = _toStringMap(item);
    final localId = _stringOrNull(json['localId']);
    final id = _stringOrNull(json['id']) ?? localId ?? _fallbackTransactionId(json);
    final rawComment =
        _stringOrNull(json['comment']) ??
            _stringOrNull(json['description']) ??
            _stringOrNull(json['title']) ??
            '';

    final date = _normalizeDate(_stringOrNull(json['date']));

    final isUpdate = json['isUpdate'] == true;
    final originalId = _stringOrNull(json['originalId']);
    final originalCategoryId = _stringOrNull(json['originalCategoryId']);

    return {
      if (localId != null) 'localId': localId,
      'id': id,
      'type': _normalizeType(json['type']),
      'amount': _normalizeAmount(json['amount']),
      'categoryId': _stringOrNull(json['categoryId']) ?? '',
      'categoryName': _stringOrNull(json['categoryName']) ?? '',
      'date': date,
      'title': _stringOrNull(json['title']) ?? rawComment,
      'description': _stringOrNull(json['description']) ?? rawComment,
      'comment': rawComment,

      'syncStatus': _stringOrNull(json['syncStatus']) ?? defaultSyncStatus,

      if (isUpdate) 'isUpdate': true,
      if (originalId != null) 'originalId': originalId,
      if (originalCategoryId != null) 'originalCategoryId': originalCategoryId,
    };
  }

  static Map<String, dynamic> normalizeCategoryJson(dynamic item) {
    final json = _toStringMap(item);
    return {
      'id': _stringOrNull(json['id']) ?? '',
      'name': _stringOrNull(json['name']) ?? 'Без названия',
    };
  }

  static Map<String, dynamic> _toStringMap(dynamic item) {
    if (item is Map) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }

    return {};
  }

  static String? _stringOrNull(dynamic value) {
    final stringValue = value?.toString();
    if (stringValue == null || stringValue.isEmpty) {
      return null;
    }

    return stringValue;
  }

  static String _normalizeType(dynamic value) {
    return value?.toString() == 'income' ? 'income' : 'expense';
  }

  static double _normalizeAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  static String _normalizeDate(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    final date = parsed ?? DateTime.now();

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _fallbackTransactionId(Map<String, dynamic> json) {
    final source = [
      json['date'],
      json['amount'],
      json['type'],
      json['comment'] ?? json['description'] ?? json['title'],
    ].whereType<Object>().join('-');

    return 'local-${source.hashCode}';
  }

  static bool _isUuid(dynamic value) {
    final text = value?.toString();
    if (text == null) {
      return false;
    }

    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(text);
  }

  static Future<void> _cacheCategoryFromTransaction(
    Box box,
    Map<String, dynamic> transaction,
  ) async {
    final category = _categoryFromTransaction(transaction);
    if (category == null) {
      return;
    }

    await box.put(category['id'], category);
  }

  static Map<String, dynamic>? _categoryFromTransaction(
    Map<String, dynamic> transaction,
  ) {
    final id = _stringOrNull(transaction['categoryId']);
    final name = _stringOrNull(transaction['categoryName']);

    if (id == null || name == null) {
      return null;
    }

    return {
      'id': id,
      'name': name,
    };
  }
}
