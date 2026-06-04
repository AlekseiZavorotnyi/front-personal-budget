import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/transaction_model.dart';
import '../../core/providers/api_providers.dart';
import '../stats/stats_providers.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;

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

final transactionFiltersProvider =
StateProvider<TransactionFilterState>((ref) => const TransactionFilterState());



final transactionsProvider = FutureProvider((ref) async {
  final api = ref.watch(apiClientProvider);
  final filters = ref.watch(transactionFiltersProvider);

  final offlineBox = await Hive.openBox('offline_transactions');

  final qp = <String, dynamic>{};

  if (filters.categoryId != null) {
    qp["categoryId"] = filters.categoryId;
  }
  if (filters.type != null) qp["type"] = filters.type;
  if (filters.from != null) qp["from"] = filters.from!.toIso8601String().split("T").first;
  if (filters.to != null) qp["to"] = filters.to!.toIso8601String().split("T").first;

  List<TransactionModel> serverList = [];

  try {
    final response = await api.dio.get('/api/transactions', queryParameters: qp);
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List;
    serverList = items.map((e) => TransactionModel.fromJson(e)).toList();
  } catch (_) {
    // офлайн — просто не грузим сервер
  }

  final offlineList = offlineBox.values
      .map((e) => TransactionModel.fromJson(e))
      .toList();

  return [...offlineList, ...serverList];
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
    final offlineBox = await Hive.openBox('offline_transactions');

    try {
      await api.dio.post(
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

      ref.invalidate(transactionsProvider);
      ref.invalidate(balanceProvider);
      ref.invalidate(statsSummaryProvider);
      ref.invalidate(statsByCategoryProvider);
      ref.invalidate(statsMonthlyProvider);
    } catch (_) {
      final localId = const Uuid().v4();

      await offlineBox.put(localId, {
        "localId": localId,
        "type": type,
        "amount": amount,
        "date": date,
        "categoryId": categoryId,
        "title": comment,
        "description": comment,
      });

      ref.invalidate(transactionsProvider);
    }
  }

  return addTransaction;
});



final deleteTransactionProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);

  Future<void> deleteTransaction(String id) async {
    await api.dio.delete('/api/transactions/$id');

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
    await api.dio.patch(
      '/api/transactions/$id',
      data: {
        "type": type,
        "amount": amount,
        "date": date,
        "comment": comment,
        "description": comment,
        "categoryId": categoryId,
      },
    );

    ref.invalidate(transactionsProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(statsSummaryProvider);
    ref.invalidate(statsByCategoryProvider);
    ref.invalidate(statsMonthlyProvider);
  }

  return updateTransaction;
});


Future<void> syncOfflineTransactions(WidgetRef ref) async {
  final api = ref.read(apiClientProvider);
  final box = await Hive.openBox('offline_transactions');

  if (box.isEmpty) return;

  final items = box.values.toList();

  try {
    final response = await api.dio.post(
      '/sync/transactions',
      data: {"transactions": items},
    );

    final synced = response.data["synced"] as List;

    for (final r in synced) {
      if (r["status"] == "synced") {
        await box.delete(r["localId"]);
      }
    }

    ref.invalidate(transactionsProvider);
  } catch (_) {}
}



