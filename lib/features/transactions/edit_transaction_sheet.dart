import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category_model.dart';
import '../transactions/transactions_providers.dart';
import '../../core/models/transaction_model.dart';
import 'categories_providers.dart';

class EditTransactionSheet extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const EditTransactionSheet({super.key, required this.transaction});

  @override
  ConsumerState<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends ConsumerState<EditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  late String type;
  late double amount;
  late String comment;
  late DateTime date;
  late String? categoryId;

  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    type = widget.transaction.type;
    amount = widget.transaction.amount;
    comment = widget.transaction.comment ?? "";
    date = widget.transaction.date;
    categoryId = widget.transaction.categoryId;

    _amountController.text = amount.toString();
    _commentController.text = comment;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updateTransaction = ref.watch(updateTransactionProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Редактировать транзакцию",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _TypeSelector(
                      type: type,
                      onChanged: (v) => setState(() => type = v),
                    ),
                    const SizedBox(height: 16),
                    _AmountField(
                      controller: _amountController,
                      onChanged: (v) => amount = double.tryParse(v) ?? 0,
                    ),
                    const SizedBox(height: 16),
                    _CategoryField(
                      categoriesAsync: categoriesAsync,
                      categoryId: categoryId,
                      onCategoryChanged: (id) => setState(() => categoryId = id),
                      ref: ref,
                    ),
                    const SizedBox(height: 16),
                    _CommentField(
                      controller: _commentController,
                      onChanged: (v) => comment = v,
                    ),
                    const SizedBox(height: 16),
                    _DatePicker(
                      date: date,
                      onDateChanged: (d) => setState(() => date = d),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) _ErrorWidget(error: _error!),
                  ],
                ),
              ),
            ),
          ),

          _SubmitButton(
            isSaving: _isSaving,
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              setState(() {
                _isSaving = true;
                _error = null;
              });

              try {
                await updateTransaction(
                  id: widget.transaction.id,
                  type: type,
                  amount: amount,
                  date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  comment: comment,
                  categoryId: categoryId,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Транзакция обновлена')),
                  );
                  Navigator.pop(context);
                }
              } catch (error) {
                if (!mounted) return;
                setState(() {
                  _error = _formatError(error);
                });
              } finally {
                if (mounted) {
                  setState(() {
                    _isSaving = false;
                  });
                }
              }
            },
          ),
        ],
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
        return "Сервер вернул ошибку $statusCode";
      }

      return "Не удалось обновить транзакцию";
    }

    return "Не удалось обновить транзакцию";
  }
}

class _TypeSelector extends StatelessWidget {
  final String type;
  final ValueChanged<String> onChanged;

  const _TypeSelector({
    required this.type,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              label: 'Расход',
              value: 'expense',
              selected: type == 'expense',
              icon: Icons.trending_down,
              color: Colors.red,
              onTap: () => onChanged('expense'),
            ),
          ),
          Expanded(
            child: _TypeButton(
              label: 'Доход',
              value: 'income',
              selected: type == 'income',
              icon: Icons.trending_up,
              color: Colors.green,
              onTap: () => onChanged('income'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _AmountField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: "Сумма",
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      validator: (v) {
        final amount = double.tryParse((v ?? "").trim().replaceAll(",", "."));
        if (amount == null) return "Введите число";
        if (amount <= 0) return "Сумма должна быть больше нуля";
        return null;
      },
    );
  }
}

class _CategoryField extends ConsumerStatefulWidget {
  final AsyncValue<List<CategoryModel>> categoriesAsync;
  final String? categoryId;
  final ValueChanged<String?> onCategoryChanged;
  final WidgetRef ref;

  const _CategoryField({
    required this.categoriesAsync,
    required this.categoryId,
    required this.onCategoryChanged,
    required this.ref,
  });

  @override
  ConsumerState<_CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends ConsumerState<_CategoryField> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.categoriesAsync.when(
      data: (categories) {
        final filteredCategories = _searchQuery.isEmpty
            ? categories
            : categories.where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => _CategorySearchSheet(
                    categories: categories,
                    selectedId: widget.categoryId,
                    onSelected: widget.onCategoryChanged,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          widget.categoryId == null
                              ? "Выберите категорию"
                              : categories.firstWhere(
                                (c) => c.id == widget.categoryId,
                            orElse: () => CategoryModel(id: "", name: "Не найдено"),
                          ).name,
                          style: TextStyle(
                            color: widget.categoryId == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (_) => const _AddCategoryDialog(),
                );
                if (name != null && name.isNotEmpty) {
                  final addCategory = widget.ref.read(addCategoryProvider);
                  await addCategory(name);
                  widget.ref.invalidate(categoriesProvider);
                }
              },
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text("Новая категория"),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Text("Ошибка загрузки категорий"),
    );
  }
}

class _CategorySearchSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _CategorySearchSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<_CategorySearchSheet> createState() => _CategorySearchSheetState();
}

class _CategorySearchSheetState extends State<_CategorySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _searchQuery.isEmpty
        ? widget.categories
        : widget.categories.where((c) =>
        c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Поиск категории...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.all_inclusive),
                  title: const Text("Все категории"),
                  selected: widget.selectedId == null,
                  selectedTileColor: Colors.blue.shade50,
                  onTap: () {
                    widget.onSelected(null);
                    Navigator.pop(context);
                  },
                ),
                ...filteredCategories.map((c) {
                  return ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(c.name),
                    selected: widget.selectedId == c.id,
                    selectedTileColor: Colors.blue.shade50,
                    onTap: () {
                      widget.onSelected(c.id);
                      Navigator.pop(context);
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

class _CommentField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CommentField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: "Комментарий (необязательно)",
        prefixIcon: const Icon(Icons.comment),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: 2,
      onChanged: onChanged,
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  const _DatePicker({
    required this.date,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDate: date,
        );
        if (picked != null) onDateChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;

  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(error, style: TextStyle(color: Colors.red.shade700))),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: FilledButton(
          onPressed: isSaving ? null : onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text("Сохранить изменения"),
        ),
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog();

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  String name = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Новая категория"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: TextField(
        autofocus: true,
        decoration: const InputDecoration(
          labelText: "Название категории",
          border: OutlineInputBorder(),
        ),
        onChanged: (v) => name = v,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        FilledButton(
          onPressed: () {
            if (name.trim().isEmpty) return;
            Navigator.pop(context, name.trim());
          },
          child: const Text("Добавить"),
        ),
      ],
    );
  }
}