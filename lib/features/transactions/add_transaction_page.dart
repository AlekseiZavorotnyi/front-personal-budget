import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_personal_budget/features/transactions/transactions_providers.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(title: const Text("Добавить транзакцию")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: "income", child: Text("Доход")),
                  DropdownMenuItem(value: "expense", child: Text("Расход")),
                ],
                onChanged: (v) => setState(() => type = v!),
                decoration: const InputDecoration(labelText: "Тип"),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Сумма"),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final amount = _parseAmount(v);

                  if (amount == null) {
                    return "Введите число";
                  }

                  if (amount <= 0) {
                    return "Сумма должна быть больше нуля";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              categoriesAsync.when(
                data: (categories) {
                  return DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    items: categories
                        .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => categoryId = v),
                    decoration: const InputDecoration(labelText: "Категория"),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Text("Ошибка загрузки категорий"),
              ),

              if (categoryId != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: "Удалить категорию",
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Удалить категорию?"),
                          content: const Text("Все транзакции с этой категорией останутся, но categoryId станет null."),
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

                      if (confirm == true) {
                        final deleteCategory = ref.read(deleteCategoryProvider);
                        await deleteCategory(categoryId!);

                        setState(() => categoryId = null);

                        ref.invalidate(categoriesProvider);
                      }
                    },
                  ),
                ),


              TextButton(
                onPressed: () async {
                  final name = await showDialog<String>(
                    context: context,
                    builder: (_) => _AddCategoryDialog(),
                  );

                  if (name != null && name.isNotEmpty) {
                    final addCategory = ref.read(addCategoryProvider);
                    await addCategory(name);

                    ref.invalidate(categoriesProvider);
                  }
                },
                child: const Text("Добавить категорию"),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(labelText: "Комментарий"),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDate: date,
                  );
                  if (picked != null) setState(() => date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Дата",
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_month_rounded),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],

              FilledButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        setState(() {
                          _isSaving = true;
                          _error = null;
                        });

                        try {
                          await addTransaction(
                            type: type,
                            amount: _parseAmount(_amountController.text)!,
                            date: date.toIso8601String().substring(0, 10),
                            comment: _commentController.text.trim(),
                            categoryId: categoryId
                          );

                          if (context.mounted) {
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
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Добавить"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? _parseAmount(String? value) {
    return double.tryParse((value ?? "").trim().replaceAll(",", "."));
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

            // Возвращаем JSON с name и type
            Navigator.pop(context, name.trim());
          },
          child: const Text("Добавить"),
        ),
      ],
    );
  }
}
