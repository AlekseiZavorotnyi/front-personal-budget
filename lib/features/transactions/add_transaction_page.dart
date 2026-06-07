import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_personal_budget/features/transactions/transactions_providers.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/category_model.dart';
import 'categories_providers.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  String? categoryId;
  String type = "expense";
  DateTime date = DateTime.now();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addTransaction = ref.watch(addTransactionProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Добавить транзакцию"),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeSelector(type: type, onChanged: (v) => setState(() => type = v)),
                    const SizedBox(height: 16),
                    _AmountField(controller: _amountController),
                    const SizedBox(height: 16),
                    _CategoryField(
                      categoriesAsync: categoriesAsync,
                      categoryId: categoryId,
                      onCategoryChanged: (id) => setState(() => categoryId = id),
                      onCategoryDeleted: () {
                        setState(() => categoryId = null);
                        ref.invalidate(categoriesProvider);
                      },
                      ref: ref,
                    ),
                    const SizedBox(height: 16),
                    _DatePicker(date: date, onDateChanged: (d) => setState(() => date = d)),
                    const SizedBox(height: 16),
                    _CommentField(controller: _commentController),
                    const SizedBox(height: 24),
                    if (_error != null) _ErrorWidget(error: _error!),
                    const SizedBox(height: 16),
                  ],
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
                  await addTransaction(
                    type: type,
                    amount: double.parse(_amountController.text),
                    date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                    comment: _commentController.text.trim(),
                    categoryId: categoryId,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Транзакция добавлена')),
                    );
                    context.pop();
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

      return "Не удалось добавить транзакцию";
    }

    return "Не удалось добавить транзакцию";
  }
}

class _TypeSelector extends StatelessWidget {
  final String type;
  final ValueChanged<String> onChanged;

  const _TypeSelector({required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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

  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
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
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: "Сумма",
          hintText: "0.00",
          prefixIcon: const Icon(Icons.currency_ruble),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          final amount = double.tryParse((v ?? "").trim().replaceAll(",", "."));
          if (amount == null) return "Введите число";
          if (amount <= 0) return "Сумма должна быть больше нуля";
          return null;
        },
      ),
    );
  }
}

class _CategoryField extends ConsumerStatefulWidget {
  final AsyncValue<List<CategoryModel>> categoriesAsync;
  final String? categoryId;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onCategoryDeleted;
  final WidgetRef ref;

  const _CategoryField({
    required this.categoriesAsync,
    required this.categoryId,
    required this.onCategoryChanged,
    required this.onCategoryDeleted,
    required this.ref,
  });

  @override
  ConsumerState<_CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends ConsumerState<_CategoryField> {
  @override
  Widget build(BuildContext context) {
    return widget.categoriesAsync.when(
      data: (categories) {
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
          child: Column(
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
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
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
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    if (widget.categoryId != null)
                      TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Удалить категорию?"),
                              content: const Text(
                                "Все транзакции с этой категорией останутся, но categoryId станет null.",
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          if (confirm == true) {
                            final deleteCategory = widget.ref.read(deleteCategoryProvider);
                            await deleteCategory(widget.categoryId!);
                            widget.onCategoryDeleted();
                            widget.ref.invalidate(categoriesProvider);
                          }
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        label: const Text("Удалить", style: TextStyle(color: Colors.red)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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

class _DatePicker extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  const _DatePicker({required this.date, required this.onDateChanged});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
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
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2030),
            initialDate: date,
          );
          if (picked != null) onDateChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(date),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentField extends StatelessWidget {
  final TextEditingController controller;

  const _CommentField({required this.controller});

  @override
  Widget build(BuildContext context) {
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
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: "Комментарий (необязательно)",
          hintText: "Введите комментарий...",
          prefixIcon: const Icon(Icons.comment),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        maxLines: 3,
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

  const _SubmitButton({required this.isSaving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
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
            backgroundColor: Colors.blue,
          ),
          child: isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text(
            "Добавить транзакцию",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
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
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Новая категория"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: "Название категории",
          hintText: "Введите название",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isEmpty) return;
            Navigator.pop(context, _controller.text.trim());
          },
          child: const Text("Добавить"),
        ),
      ],
    );
  }
}