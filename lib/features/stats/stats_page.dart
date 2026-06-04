import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_personal_budget/features/stats/stats_providers.dart';

import '../../core/models/category_model.dart';
import '../../core/models/stats_model.dart';
import '../transactions/categories_providers.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Отчёты"),
        bottom: TabBar(
          controller: controller,
          tabs: const [
            Tab(text: "Сводка"),
            Tab(text: "Категории"),
            Tab(text: "Месяцы"),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller,
        children: const [
          StatsSummaryTab(),
          StatsByCategoryTab(),
          StatsMonthlyTab(),
        ],
      ),
    );
  }
}

class StatsSummaryTab extends ConsumerWidget {
  const StatsSummaryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final from = ref.watch(statsFromProvider);
    final to = ref.watch(statsToProvider);

    final stats = ref.watch(
      statsSummaryProvider((from: from, to: to)),
    );

    return stats.when(
      data: (s) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _periodSelector(context, ref),

          const SizedBox(height: 16),

          _summaryCard(
            title: "Доходы",
            value: s.totalIncome,
            color: Colors.green,
          ),
          _summaryCard(
            title: "Расходы",
            value: s.totalExpenses,
            color: Colors.red,
          ),
          _summaryCard(
            title: "Баланс",
            value: s.balance,
            color: s.balance >= 0 ? Colors.green : Colors.red,
          ),

          const SizedBox(height: 12),
          Text(
            "Транзакций: ${s.transactionCount}",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
    );
  }

  Widget _summaryCard({required String title, required double value, required Color color}) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            Text(
              "${value.toStringAsFixed(2)} ₽",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsByCategoryTab extends ConsumerStatefulWidget {
  const StatsByCategoryTab({super.key});

  @override
  ConsumerState<StatsByCategoryTab> createState() => _StatsByCategoryTabState();
}

class _StatsByCategoryTabState extends ConsumerState<StatsByCategoryTab> {
  String? type;

  @override
  Widget build(BuildContext context) {
    final from = ref.watch(statsFromProvider);
    final to = ref.watch(statsToProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    final stats = ref.watch(
      statsByCategoryProvider((from: from, to: to, type: type)),
    );

    return Column(
      children: [
        _periodSelector(context, ref),

        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButton<String?>(
            value: type,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: null, child: Text("Все")),
              DropdownMenuItem(value: "income", child: Text("Доходы")),
              DropdownMenuItem(value: "expense", child: Text("Расходы")),
            ],
            onChanged: (v) => setState(() => type = v),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: stats.when(
            data: (s) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Всего: ${s.total.toStringAsFixed(2)} ₽",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                ...s.items.map((i) => _categoryItem(i)),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Ошибка: $e")),
          ),
        ),
      ],
    );
  }

  Widget _categoryItem(CategoryStatsItem i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i.categoryName ?? "Без категории",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: i.percentage / 100,
            color: Colors.blue,
            backgroundColor: Colors.blue.withOpacity(0.15),
          ),
          const SizedBox(height: 4),
          Text(
            "${i.total.toStringAsFixed(2)} ₽ • ${i.percentage.toStringAsFixed(1)}%",
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}


class StatsMonthlyTab extends ConsumerWidget {
  const StatsMonthlyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(statsYearProvider);
    final stats = ref.watch(statsMonthlyProvider(year));

    final years = List.generate(5, (i) => DateTime.now().year - i);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButton<int>(
            value: year,
            isExpanded: true,
            items: years
                .map((y) => DropdownMenuItem(
              value: y,
              child: Text("$y год"),
            ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ref.read(statsYearProvider.notifier).state = v;
              }
            },
          ),
        ),

        Expanded(
          child: stats.when(
            data: (s) => ListView(
              padding: const EdgeInsets.all(16),
              children: s.months.map((m) {
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(m.label),
                    subtitle: Text(
                      "Доходы: ${m.totalIncome} ₽\n"
                          "Расходы: ${m.totalExpenses} ₽",
                    ),
                    trailing: Text(
                      "${m.balance} ₽",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: m.balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Ошибка: $e")),
          ),
        ),
      ],
    );
  }
}

Widget _periodSelector(BuildContext context, WidgetRef ref) {
  final from = ref.watch(statsFromProvider);
  final to = ref.watch(statsToProvider);

  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDate: from ?? DateTime.now(),
            );
            if (picked != null) {
              ref.read(statsFromProvider.notifier).state = picked;
            }
          },
          child: Text(from == null ? "С даты" : from.toString().split(" ").first),
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
              initialDate: to ?? DateTime.now(),
            );
            if (picked != null) {
              ref.read(statsToProvider.notifier).state = picked;
            }
          },
          child: Text(to == null ? "По дату" : to.toString().split(" ").first),
        ),
      ),
    ],
  );
}

class CategoryDropdown extends ConsumerStatefulWidget {
  const CategoryDropdown({super.key});

  @override
  ConsumerState<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends ConsumerState<CategoryDropdown> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(categorySearchProvider);
    final categories = ref.watch(filteredCategoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Поиск категории",
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            ref.read(categorySearchProvider.notifier).state = value;
          },
        ),

        const SizedBox(height: 12),

        DropdownMenu<String?>(
          initialSelection: selected,
          width: MediaQuery.of(context).size.width - 32,
          menuHeight: 300,
          onSelected: (value) {
            ref.read(selectedCategoryProvider.notifier).state = value;
          },
          dropdownMenuEntries: [
            const DropdownMenuEntry(
              value: null,
              label: "Все категории",
            ),
            ...categories.map(
                  (c) => DropdownMenuEntry(
                value: c.id,
                label: c.name,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CategoryPickerButton extends ConsumerWidget {
  final String? value;
  final void Function(String? id) onChanged;

  const CategoryPickerButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.when(
      loading: () => const OutlinedButton(
        onPressed: null,
        child: Text("Загрузка категорий..."),
      ),
      error: (e, _) => OutlinedButton(
        onPressed: null,
        child: Text("Ошибка категорий"),
      ),
      data: (categories) {
        final selectedName = value == null
            ? "Все категории"
            : categories
            .firstWhere(
              (c) => c.id == value,
          orElse: () => CategoryModel(id: "", name: "Не найдено"),
        )
            .name;

        return OutlinedButton(
          onPressed: () async {
            final result = await showModalBottomSheet<String?>(
              context: context,
              isScrollControlled: true,
              builder: (_) => CategoryPickerSheet(initial: value),
            );

            onChanged(result);
          },
          child: Text(selectedName),
        );
      },
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
  Widget build(BuildContext context) {
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
            decoration: const InputDecoration(
              labelText: "Поиск категории",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
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
                  title: const Text("Все категории"),
                  selected: localSelected == null,
                  onTap: () {
                    Navigator.pop<String?>(context, null);
                  },
                ),
                ...categories.map((c) {
                  return ListTile(
                    title: Text(c.name),
                    selected: localSelected == c.id,
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

