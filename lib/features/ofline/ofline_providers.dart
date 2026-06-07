import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/api_providers.dart';
import '../../core/services/local_budget_cache.dart';
import '../stats/stats_providers.dart';
import '../transactions/categories_providers.dart';
import '../transactions/transactions_providers.dart';
import 'browser_connectivity_stub.dart'
    if (dart.library.html) 'browser_connectivity_web.dart' as browser;

final syncWorkerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) async {
    if (next.valueOrNull == true) {
      await syncAll(ref);
    }
  }, fireImmediately: true);
});

final connectivityProvider = StreamProvider<bool>((ref) async* {
  yield browser.isOnline;
  yield* browser.connectivityChanges();
});

bool _isSyncing = false;

Future<void> syncAll(Ref ref) async {
  if (_isSyncing) return;
  _isSyncing = true;
  try {
    await syncOfflineCategories(ref);
    await syncOfflineTransactions(ref);
  } finally {
    _isSyncing = false;
  }
}

Future<void> syncOfflineTransactions(Ref ref) async {
  final api = ref.read(apiClientProvider);
  final items = await LocalBudgetCache.readOfflineTransactionPayloads();

  if (items.isEmpty) return;

  try {
    final response = await api.dio.post(
      '/api/sync/transactions',
      data: {"transactions": items},
    );

    final synced = response.data["synced"] as List;

    for (final r in synced) {
      if (r["status"] == "synced") {
        final transaction = r["transaction"];
        final localId = r["localId"];

        if (transaction != null) {
          await LocalBudgetCache.upsertServerTransaction(transaction);
        }

        if (localId != null) {
          await LocalBudgetCache.deleteOfflineTransaction(localId.toString());
        }
      }
    }

    ref.invalidate(transactionsProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(statsSummaryProvider);
    ref.invalidate(statsByCategoryProvider);
    ref.invalidate(statsMonthlyProvider);
  } catch (_) {}
}

Future<void> syncOfflineCategories(Ref ref) async {
  final api = ref.read(apiClientProvider);
  final items = await LocalBudgetCache.readOfflineCategories();

  if (items.isEmpty) return;

  for (final item in items) {
    final id = item['id'].toString();
    final name = item['name']?.toString();
    final op = item['operation'];

    try {
      if (op == 'create') {
        String? newId;

        try {
          final response = await api.dio.post('/api/categories', data: {
            'name': name,
            'type': "expense",
          });

          await LocalBudgetCache.upsertCategory(response.data);
          newId = response.data['id']?.toString();
        } on DioException catch (error) {
          if (error.response == null) {
            rethrow;
          }

          newId = await _resolveServerCategoryId(api, name);
          if (newId == null) {
            rethrow;
          }
        }

        if (newId != null && newId.isNotEmpty) {
          await LocalBudgetCache.remapCategoryId(
            oldId: id,
            newId: newId,
            newName: name,
          );
        }
      }

      if (op == 'update') {
        final response = await api.dio.patch('/api/categories/$id', data: {
          'name': name,
          'type': "expense",
        });

        await LocalBudgetCache.upsertCategory(response.data);
      }

      if (op == 'delete') {
        await api.dio.delete('/api/categories/$id');
        await LocalBudgetCache.removeCategory(id);
      }

      await LocalBudgetCache.removeOfflineCategory(id);
    } catch (_) {
    }
  }

  ref.invalidate(categoriesProvider);
  ref.invalidate(transactionsProvider);
}

Future<String?> _resolveServerCategoryId(dynamic api, String? name) async {
  if (name == null) return null;

  try {
    final response = await api.dio.get('/api/categories');
    final items = response.data['items'] as List;
    for (final category in items) {
      if (category['name']?.toString() == name) {
        return category['id']?.toString();
      }
    }
  } catch (_) {}

  return null;
}
