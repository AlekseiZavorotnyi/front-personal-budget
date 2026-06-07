import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_personal_budget/features/stats/stats_providers.dart';
import 'package:intl/intl.dart';

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
        elevation: 0,
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: controller,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.summarize), text: "Сводка"),
            Tab(icon: Icon(Icons.pie_chart), text: "Категории"),
            Tab(icon: Icon(Icons.calendar_month), text: "Месяцы"),
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

    final statsAsync = ref.watch(
      statsSummaryProvider((from: from, to: to)),
    );

    return statsAsync.when(
      data: (statsResponse) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _PeriodSelector(),
          const SizedBox(height: 24),
          _SummaryGrid(stats: statsResponse),
          const SizedBox(height: 16),
          _TransactionCountCard(count: statsResponse.transactionCount),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final StatsSummaryResponse stats;

  const _SummaryGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _AnimatedSummaryCard(
          title: "Доходы",
          value: stats.totalIncome,
          color: Colors.green,
          icon: Icons.trending_up,
        ),
        _AnimatedSummaryCard(
          title: "Расходы",
          value: stats.totalExpenses,
          color: Colors.red,
          icon: Icons.trending_down,
        ),
        _AnimatedSummaryCard(
          title: "Баланс",
          value: stats.balance,
          color: stats.balance >= 0 ? Colors.green : Colors.red,
          icon: Icons.account_balance_wallet,
        ),
      ],
    );
  }
}

class _AnimatedSummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;

  const _AnimatedSummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      builder: (context, double val, child) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${val.toStringAsFixed(2)} ₽",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TransactionCountCard extends StatelessWidget {
  final int count;

  const _TransactionCountCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, color: Colors.blue),
            const SizedBox(width: 12),
            Text(
              "Всего транзакций: $count",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
    final statsAsync = ref.watch(
      statsByCategoryProvider((from: from, to: to, type: type)),
    );

    return Column(
      children: [
        const _PeriodSelector(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String?>(
            segments: const [
              ButtonSegment(value: null, label: Text("Все"), icon: Icon(Icons.all_inclusive)),
              ButtonSegment(value: "income", label: Text("Доходы"), icon: Icon(Icons.trending_up)),
              ButtonSegment(value: "expense", label: Text("Расходы"), icon: Icon(Icons.trending_down)),
            ],
            selected: {type},
            onSelectionChanged: (set) => setState(() => type = set.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.blue;
                }
                return Colors.grey[200];
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.black87;
              }),
            ),
          ),
        ),
        Expanded(
          child: statsAsync.when(
            data: (categoryStats) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Общая сумма:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "${categoryStats.total.toStringAsFixed(2)} ₽",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: type == "income" ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...categoryStats.items.map((i) => _CategoryStatsItem(i)),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Ошибка: $e")),
          ),
        ),
      ],
    );
  }

  Widget _CategoryStatsItem(CategoryStatsItem i) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    i.categoryName ?? "Без категории",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "${i.total.toStringAsFixed(2)} ₽",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: i.percentage / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                i.percentage > 50 ? Colors.red : Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${i.percentage.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearSelector extends StatefulWidget {
  final int selectedYear;
  final ValueChanged<int> onYearChanged;

  const _YearSelector({
    required this.selectedYear,
    required this.onYearChanged,
  });

  @override
  State<_YearSelector> createState() => _YearSelectorState();
}

class _YearSelectorState extends State<_YearSelector> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedYear.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _confirmYear() {
    final inputYear = int.tryParse(_controller.text.trim());
    final currentYear = DateTime.now().year;

    if (inputYear != null && inputYear >= 2000 && inputYear <= currentYear) {
      widget.onYearChanged(inputYear);
      setState(() {
        _isEditing = false;
      });
    } else {
      _controller.text = widget.selectedYear.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Год должен быть от 2000 до ${currentYear}"),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = widget.selectedYear.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: _isEditing
                  ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Введите год (2000-${currentYear})",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: _confirmYear,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _cancelEditing,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                onSubmitted: (_) => _confirmYear(),
                autofocus: true,
              )
                  : GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditing = true;
                  });
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _focusNode.requestFocus();
                    _controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controller.text.length,
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(
                        "${widget.selectedYear} год",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsMonthlyTab extends ConsumerWidget {
  const StatsMonthlyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(statsYearProvider);
    final statsAsync = ref.watch(statsMonthlyProvider(year));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _YearSelector(
            selectedYear: year,
            onYearChanged: (newYear) {
              ref.read(statsYearProvider.notifier).state = newYear;
            },
          ),
        ),
        Expanded(
          child: statsAsync.when(
            data: (monthlyStats) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: monthlyStats.months.length,
              itemBuilder: (context, index) {
                final m = monthlyStats.months[index];
                return _MonthlyCard(monthItem: m);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Ошибка: $e")),
          ),
        ),
      ],
    );
  }
}

class _MonthlyCard extends StatelessWidget {
  final MonthlyStatsItem monthItem;

  const _MonthlyCard({required this.monthItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: monthItem.balance >= 0 ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            monthItem.balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            color: monthItem.balance >= 0 ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          monthItem.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "Баланс: ${monthItem.balance.toStringAsFixed(2)} ₽",
          style: TextStyle(
            color: monthItem.balance >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Доходы: +${monthItem.totalIncome.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 12, color: Colors.green),
            ),
            Text(
              "Расходы: -${monthItem.totalExpenses.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.trending_up,
                  label: "Доходы",
                  value: monthItem.totalIncome,
                  color: Colors.green,
                ),
                const Divider(),
                _DetailRow(
                  icon: Icons.trending_down,
                  label: "Расходы",
                  value: monthItem.totalExpenses,
                  color: Colors.red,
                ),
                const Divider(),
                _DetailRow(
                  icon: Icons.account_balance_wallet,
                  label: "Баланс",
                  value: monthItem.balance,
                  color: monthItem.balance >= 0 ? Colors.green : Colors.red,
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final bool isBold;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        Text(
          "${value.toStringAsFixed(2)} ₽",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final from = ref.watch(statsFromProvider);
    final to = ref.watch(statsToProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DateButton(
              label: from == null ? "С даты" : DateFormat('dd.MM.yyyy').format(from),
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
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, color: Colors.grey),
          ),
          Expanded(
            child: _DateButton(
              label: to == null ? "По дату" : DateFormat('dd.MM.yyyy').format(to),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DateButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}