import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/api_providers.dart';
import '../../core/services/token_storage.dart';
import '../stats/stats_page.dart';
import '../transactions/transactions_providers.dart';
import 'categories_providers.dart';
import 'edit_transaction_sheet.dart';

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
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => context.push('/stats'),
          ),
          IconButton(
            tooltip: "Категории",
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.push('/categories'),
          ),
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
              error: (e, _) => Text('Ошибка: ${_formatError(e)}'),
            ),

            const SizedBox(height: 24),

            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const TransactionsFilterSheet(),
                );
              },
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
                      final deleteTransaction = ref.read(deleteTransactionProvider);

                      return Dismissible(
                        key: ValueKey(t.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Удалить транзакцию?"),
                              content: const Text("Это действие нельзя отменить."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Отмена"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Удалить"),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) async {
                          list.removeAt(i);
                          ref.invalidate(transactionsProvider);
                          await deleteTransaction(t.id);
                        },
                        child: ListTile(
                          leading: Icon(
                            t.type == "income" ? Icons.arrow_upward : Icons.arrow_downward,
                            color: t.type == "income" ? Colors.green : Colors.red,
                          ),
                          title: Text(t.categoryName ?? "Без категории"),
                          subtitle: Text(t.comment ?? "Без комментария"),
                          trailing: Text(
                            '${t.type == "income" ? "+" : "-"}${t.amount} ₽',
                            style: TextStyle(
                              color: t.type == "income" ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => EditTransactionSheet(transaction: t),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Ошибка: ${_formatError(e)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      if (responseData is Map && responseData['message'] != null) {
        return responseData['message'].toString();
      }

      if (statusCode != null) {
        return 'сервер вернул ошибку $statusCode';
      }

      return 'не удалось получить транзакции';
    }

    final message = error.toString();
    const exceptionPrefix = 'Exception: ';

    if (message.startsWith(exceptionPrefix)) {
      return message.substring(exceptionPrefix.length);
    }

    return message;
  }
}

class TransactionsFilterSheet extends ConsumerStatefulWidget {
  const TransactionsFilterSheet({super.key});

  @override
  ConsumerState<TransactionsFilterSheet> createState() =>
      _TransactionsFilterSheetState();
}

class _TransactionsFilterSheetState
    extends ConsumerState<TransactionsFilterSheet> {
  DateTime? localFrom;
  DateTime? localTo;
  String? localCategoryId;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(transactionFiltersProvider);
    localFrom = filters.from;
    localTo = filters.to;
    localCategoryId = filters.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(transactionFiltersProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: localFrom ?? DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => localFrom = picked);
                    }
                  },
                  child: Text(localFrom == null
                      ? "С даты"
                      : localFrom.toString().split(" ").first),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: localTo ?? DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => localTo = picked);
                    }
                  },
                  child: Text(localTo == null
                      ? "По дату"
                      : localTo.toString().split(" ").first),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          CategoryPickerButton(
            value: localCategoryId,
            onChanged: (id) {
              setState(() => localCategoryId = id);
            },
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {
              ref.read(transactionFiltersProvider.notifier).state =
                  filters.copyWith(
                    from: localFrom,
                    to: localTo,
                    categoryId: localCategoryId,
                  );

              ref.read(selectedCategoryProvider.notifier).state =
                  localCategoryId;

              ref.invalidate(transactionsProvider);

              Navigator.pop(context);
            },
            child: const Text("Применить"),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
