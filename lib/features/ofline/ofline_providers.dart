import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/api_providers.dart';
import '../../core/services/local_budget_cache.dart';
import '../stats/stats_providers.dart';
import '../transactions/transactions_providers.dart';
import 'browser_connectivity_stub.dart'
    if (dart.library.html) 'browser_connectivity_web.dart' as browser;

final syncWorkerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) async {
    if (next.valueOrNull == true) {
      await syncOfflineTransactions(ref);
    }
  }, fireImmediately: true);
});

final connectivityProvider = StreamProvider<bool>((ref) async* {
  yield browser.isOnline;
  yield* browser.connectivityChanges();
});

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
        if (transaction != null) {
          await LocalBudgetCache.upsertServerTransaction(transaction);
        }
        await LocalBudgetCache.deleteOfflineTransaction(r["localId"]);
      }
    }

    ref.invalidate(transactionsProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(statsSummaryProvider);
    ref.invalidate(statsByCategoryProvider);
    ref.invalidate(statsMonthlyProvider);
  } catch (_) {}
}
