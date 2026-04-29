import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/transaction_model.dart';
import '../../core/providers/api_providers.dart';

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final api = ref.watch(apiClientProvider);

  final response = await api.dio.get('/api/transactions');
  final data = response.data as Map<String, dynamic>;

  if (data['mocked'] == true) {
    throw StateError('Сервер вернул моковые транзакции');
  }

  final items = data['items'] as List;

  return items.map((e) => TransactionModel.fromJson(e)).toList();
});

final balanceProvider = FutureProvider<double>((ref) async {
  final list = await ref.watch(transactionsProvider.future);
  return list.fold<double>(
    0.0,
    (sum, t) => sum + (t.type == "expense" ? -t.amount : t.amount),
  );
});

final addTransactionProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String date,
    required String comment,
  }) async {
    await api.dio.post(
      '/api/transactions',
      data: {
        "type": type,
        "amount": amount,
        "date": date,
        "comment": comment,
        "description": comment,
      },
    );

    ref.invalidate(transactionsProvider);
    ref.invalidate(balanceProvider);
  }

  return addTransaction;
});
