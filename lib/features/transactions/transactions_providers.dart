import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/transaction_model.dart';
import '../../core/providers/api_providers.dart';
import '../../core/services/local_budget_cache.dart';
import '../stats/stats_providers.dart';

final balanceProvider = FutureProvider<double>((ref) async {
  final list = await ref.watch(transactionsProvider.future);
  return list.fold<double>(
    0.0,
    (sum, t) => sum + (t.type == "expense" ? -t.amount : t.amount),
  );
});

class TransactionFilterState {
  final String? type;
  final String? categoryId;
  final DateTime? from;
  final DateTime? to;

  const TransactionFilterState({
    this.type,
    this.categoryId,
    this.from,
    this.to,
  });

  TransactionFilterState copyWith({
    String? type,
    String? categoryId,
    DateTime? from,
    DateTime? to,
  }) {
    return TransactionFilterState(
      type: type ?? this.type,
      categoryId: categoryId,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}

final transactionFiltersProvider = StateProvider<TransactionFilterState>(
  (ref) => const TransactionFilterState(),
);

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final filters = ref.watch(transactionFiltersProvider);

  final qp = <String, dynamic>{};

  if (filters.categoryId != null) {
    qp["categoryId"] = filters.categoryId;
  }
  if (filters.type != null) qp["type"] = filters.type;
  if (filters.from != null) {
    qp["from"] = filters.from!.toIso8601String().split("T").first;
  }
  if (filters.to != null) {
    qp["to"] = filters.to!.toIso8601String().split("T").first;
  }
  qp["limit"] = 500;

  final hasFilters = filters.categoryId != null ||
      filters.type != null ||
      filters.from != null ||
      filters.to != null;

  List<TransactionModel> serverList = [];

  try {
    final response = await api.dio.get('/api/transactions', queryParameters: qp);
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List;
    await LocalBudgetCache.cacheServerTransactions(
      items,
      replace: !hasFilters,
    );
    serverList = items.map((e) => TransactionModel.fromJson(e)).toList();
  } on DioException catch (error) {
    if (error.response != null) {
      rethrow;
    }

    serverList = _applyTransactionFilters(
      await LocalBudgetCache.readCachedTransactions(),
      filters,
    );
  }

  final offlineList = _applyTransactionFilters(
    await LocalBudgetCache.readOfflineTransactions(),
    filters,
  );

  final Map<String, TransactionModel> unique = {};
  for (final t in offlineList) unique[t.id] = t;
  for (final t in serverList) if (!unique.containsKey(t.id)) unique[t.id] = t;

  return _sortTransactions(unique.values.toList());
});

final addTransactionProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String date,
    required String comment,
    required String? categoryId,
  }) async {
    try {
      final response = await api.dio.post(
        '/api/transactions',
        data: {
          "type": type,
          "amount": amount,
          "date": date,
          "comment": comment,
          "description": comment,
          "categoryId": categoryId,
        },
      );

      await LocalBudgetCache.upsertServerTransaction(response.data);
      ref.invalidate(transactionsProvider);
      ref.invalidate(balanceProvider);
      ref.invalidate(statsSummaryProvider);
      ref.invalidate(statsByCategoryProvider);
      ref.invalidate(statsMonthlyProvider);
    } on DioException catch (error) {
      if (error.response != null) {
        rethrow;
      }

      final localId = const Uuid().v4();
      final categoryName = await LocalBudgetCache.categoryNameById(categoryId);

      await LocalBudgetCache.putOfflineTransaction(localId, {
        "localId": localId,
        "id": localId,
        "type": type,
        "amount": amount,
        "date": date,
        "categoryId": categoryId,
        "categoryName": categoryName,
        "comment": comment,
        "title": comment,
        "description": comment,
        "syncStatus": "pending",
      });

      ref.invalidate(transactionsProvider);
      ref.invalidate(balanceProvider);
      ref.invalidate(statsSummaryProvider);
      ref.invalidate(statsByCategoryProvider);
      ref.invalidate(statsMonthlyProvider);
    }
  }

  return addTransaction;
});

final deleteTransactionProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);

  Future<void> deleteTransaction(String id) async {
    if (await LocalBudgetCache.hasOfflineTransaction(id)) {
      await LocalBudgetCache.deleteOfflineTransaction(id);
    } else {
      await api.dio.delete('/api/transactions/$id');
      await LocalBudgetCache.removeCachedTransaction(id);
    }

    ref.invalidate(transactionsProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(statsSummaryProvider);
    ref.invalidate(statsByCategoryProvider);
    ref.invalidate(statsMonthlyProvider);
  }

  return deleteTransaction;
});

final updateTransactionProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);

  Future<void> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required String date,
    required String comment,
    required String? categoryId,
  }) async {
    final data = {
      "type": type,
      "amount": amount,
      "date": date,
      "comment": comment,
      "description": comment,
      "categoryId": categoryId,
    };

    try {
      final response = await api.dio.patch(
        '/api/transactions/$id',
        data: data,
      );

      await LocalBudgetCache.upsertServerTransaction(response.data);
    } on DioException catch (error) {
      if (error.response != null) {
        rethrow;
      }

      final categoryName = await LocalBudgetCache.categoryNameById(categoryId);
      final isPendingCreate =
          await LocalBudgetCache.isPendingOfflineCreate(id);

      await LocalBudgetCache.putOfflineTransaction(
        id,
        {
          "id": id,
          if (!isPendingCreate) "originalId": id,
          if (!isPendingCreate) "isUpdate": true,
          if (!isPendingCreate) "originalCategoryId": categoryId,
          "type": type,
          "amount": amount,
          "date": date,
          "categoryId": categoryId,
          "categoryName": categoryName,
          "comment": comment,
          "title": comment,
          "description": comment,
          "syncStatus": "pending",
        },
      );
    }

    ref.invalidate(transactionsProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(statsSummaryProvider);
    ref.invalidate(statsByCategoryProvider);
    ref.invalidate(statsMonthlyProvider);
  }

  return updateTransaction;
});



List<TransactionModel> _applyTransactionFilters(
  List<TransactionModel> transactions,
  TransactionFilterState filters,
) {
  return transactions.where((transaction) {
    if (filters.type != null && transaction.type != filters.type) {
      return false;
    }

    if (filters.categoryId != null &&
        transaction.categoryId != filters.categoryId) {
      return false;
    }

    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );

    if (filters.from != null && date.isBefore(_dateOnly(filters.from!))) {
      return false;
    }

    if (filters.to != null && date.isAfter(_dateOnly(filters.to!))) {
      return false;
    }

    return true;
  }).toList();
}

List<TransactionModel> _sortTransactions(List<TransactionModel> transactions) {
  transactions.sort((a, b) => b.date.compareTo(a.date));
  return transactions;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
