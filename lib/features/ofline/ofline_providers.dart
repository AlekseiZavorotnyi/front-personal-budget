import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/api_providers.dart';
import '../transactions/transactions_providers.dart';
import 'dart:html' as html;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

final syncWorkerProvider = Provider((ref) {
  ref.listen(connectivityProvider, (prev, next) async {
    if (next.value == true) {
      await syncOfflineTransactions(ref);
    }
  });
});


final connectivityProvider = StreamProvider<bool>((ref) async* {
  yield html.window.navigator.onLine ?? false;

  yield* Stream.multi((controller) {
    html.window.addEventListener('online', (html.Event e) {
      controller.add(true);
    });

    html.window.addEventListener('offline', (html.Event e) {
      controller.add(false);
    });
  });
});



Future<void> syncOfflineTransactions(Ref ref) async {
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

