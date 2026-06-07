import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/category_model.dart';
import '../../core/providers/api_providers.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/token_storage.dart';
import '../../core/models/transaction_model.dart';
import '../auth/auth_controller.dart';
import '../stats/stats_page.dart';
import '../stats/stats_providers.dart';
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Личный бюджет',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Статистика",
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
              ref.read(authControllerProvider.notifier).logout(context);
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(balanceProvider);
          ref.invalidate(transactionsProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BalanceCard(balanceAsync: balanceAsync),
              const SizedBox(height: 24),
              _FilterButton(),
              const SizedBox(height: 16),
              Row(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Ваши транзакции',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _AddButton(
                    onPressed: () => context.push('/add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: transactionsAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Транзакций пока нет',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/add'),
                              icon: const Icon(Icons.add),
                              label: const Text('Добавить первую транзакцию'),
                            ),
                          ],
                        ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Отмена"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text("Удалить"),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) async {
                            await deleteTransaction(t.id);
                            ref.invalidate(transactionsProvider);
                            ref.invalidate(balanceProvider);
                          },
                          child: _TransactionCard(
                            transaction: t,
                            onEdit: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => EditTransactionSheet(transaction: t),
                              ).then((_) {
                                ref.invalidate(transactionsProvider);
                                ref.invalidate(balanceProvider);
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Ошибка: ${_formatError(e)}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(transactionsProvider);
                            ref.invalidate(balanceProvider);
                          },
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        return 'Сервер вернул ошибку $statusCode';
      }

      return 'Не удалось получить транзакции';
    }

    final message = error.toString();
    const exceptionPrefix = 'Exception: ';

    if (message.startsWith(exceptionPrefix)) {
      return message.substring(exceptionPrefix.length);
    }

    return message;
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: Colors.blue,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final AsyncValue<double> balanceAsync;

  const _BalanceCard({required this.balanceAsync});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Общий баланс',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              balanceAsync.when(
                data: (balance) => Text(
                  '${balance.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const CircularProgressIndicator(color: Colors.white),
                error: (e, _) => const Text(
                  'Ошибка',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const Text(
                'Все время',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(transactionFiltersProvider);
    final hasFilters = filters.categoryId != null ||
        filters.type != null ||
        filters.from != null ||
        filters.to != null;

    return Row(
      children: [
        FilterChip(
          label: const Text('Фильтры'),
          selected: hasFilters,
          onSelected: (_) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => const TransactionsFilterSheet(),
            );
          },
          avatar: Icon(hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined, size: 20),
        ),
        if (hasFilters)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              ref.read(transactionFiltersProvider.notifier).state = const TransactionFilterState();
              ref.read(selectedCategoryProvider.notifier).state = null;
              ref.invalidate(transactionsProvider);
              ref.invalidate(balanceProvider);
            },
            tooltip: 'Сбросить фильтры',
          ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onEdit;

  const _TransactionCard({
    required this.transaction,
    required this.onEdit,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == "income";
    final amount = transaction.amount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncome ? Colors.green : Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.categoryName ?? "Без категории",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.comment ?? "Без комментария",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(transaction.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? "+" : "-"}${amount.toStringAsFixed(2)} ₽',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  String? localType;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(transactionFiltersProvider);
    localFrom = filters.from;
    localTo = filters.to;
    localCategoryId = filters.categoryId;
    localType = filters.type;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

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
          const Text(
            "Фильтры",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String?>(
              segments: const [
                ButtonSegment(
                  value: null,
                  label: Text("Все"),
                  icon: Icon(Icons.all_inclusive, size: 18),
                ),
                ButtonSegment(
                  value: "income",
                  label: Text("Доходы"),
                  icon: Icon(Icons.trending_up, size: 18),
                ),
                ButtonSegment(
                  value: "expense",
                  label: Text("Расходы"),
                  icon: Icon(Icons.trending_down, size: 18),
                ),
              ],
              selected: {localType},
              onSelectionChanged: (set) => setState(() => localType = set.first),
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(const Size(0, 40)),
                fixedSize: WidgetStateProperty.all(const Size.fromHeight(40)),
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.blue;
                  }
                  return Colors.grey.shade100;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return Colors.black87;
                }),
                side: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return BorderSide(color: Colors.blue);
                  }
                  return BorderSide(color: Colors.grey.shade300);
                }),
              ),
            ),
          ),

          const SizedBox(height: 16),

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
                      : '${localFrom!.day}.${localFrom!.month}.${localFrom!.year}'),
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
                      : '${localTo!.day}.${localTo!.month}.${localTo!.year}'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          categoriesAsync.when(
            data: (categories) {
              final selectedName = localCategoryId == null
                  ? "Все категории"
                  : categories.firstWhere(
                    (c) => c.id == localCategoryId,
                orElse: () => CategoryModel(id: "", name: "Не найдено"),
              ).name;

              return OutlinedButton(
                onPressed: () async {
                  final result = await showModalBottomSheet<String?>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => CategoryPickerSheet(initial: localCategoryId),
                  );
                  setState(() => localCategoryId = result);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedName),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text("Ошибка загрузки категорий"),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      localFrom = null;
                      localTo = null;
                      localCategoryId = null;
                      localType = null;
                    });
                  },
                  child: const Text("Сбросить"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ref.read(transactionFiltersProvider.notifier).state =
                        TransactionFilterState(
                          from: localFrom,
                          to: localTo,
                          categoryId: localCategoryId,
                          type: localType,
                        );

                    ref.read(selectedCategoryProvider.notifier).state =
                        localCategoryId;

                    ref.invalidate(transactionsProvider);
                    ref.invalidate(balanceProvider);

                    Navigator.pop(context);
                  },
                  child: const Text("Применить"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class CategoryPickerSheet extends ConsumerStatefulWidget {
  final String? initial;

  const CategoryPickerSheet({super.key, this.initial});

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet> {
  final searchController = TextEditingController();
  String? localSelected;

  @override
  void initState() {
    super.initState();
    localSelected = widget.initial;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(categorySearchProvider);
    final categories = ref.watch(filteredCategoriesProvider);

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
          TextField(
            controller: searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Поиск категории...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              ref.read(categorySearchProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 350,
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.all_inclusive),
                  title: const Text("Все категории"),
                  selected: localSelected == null,
                  selectedTileColor: Colors.blue.shade50,
                  onTap: () {
                    Navigator.pop<String?>(context, null);
                  },
                ),
                ...categories.map((c) {
                  return ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(c.name),
                    selected: localSelected == c.id,
                    selectedTileColor: Colors.blue.shade50,
                    onTap: () {
                      Navigator.pop<String?>(context, c.id);
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}