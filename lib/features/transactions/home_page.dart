import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/api_providers.dart';
import '../../core/services/token_storage.dart';
import '../transactions/transactions_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Личный бюджет'),
        actions: [
          IconButton(
            tooltip: "Выйти",
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              TokenStorage.clear();
              ref.read(isLoggedInProvider.notifier).state = false;
              context.go('/login');
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Ваш баланс',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            balanceAsync.when(
              data: (balance) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${balance.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Ошибка: $e'),
            ),

            const SizedBox(height: 24),

            const Text(
              'Последние транзакции',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: transactionsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('Транзакций пока нет'),
                    );
                  }

                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final t = list[i];
                      return ListTile(
                        leading: Icon(
                          t.type == "income"
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: t.type == "income"
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(t.categoryName ?? "Без категории"),
                        subtitle: Text(t.comment ?? "Без комментария"),
                        trailing: Text(
                          '${t.type == "income" ? "+" : "-"}${t.amount} ₽',
                          style: TextStyle(
                            color: t.type == "income"
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Ошибка: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
