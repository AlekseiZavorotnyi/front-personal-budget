import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  late String type;
  late double amount;
  late String comment;
  late DateTime date;
  late String? categoryId;


  @override
  void initState() {
    super.initState();
    type = widget.transaction.type;
    amount = widget.transaction.amount;
    comment = widget.transaction.comment ?? "";
    date = widget.transaction.date;
    categoryId = widget.transaction.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final updateTransaction = ref.watch(updateTransactionProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [

            const Text(
              "Редактировать транзакцию",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

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
              initialValue: amount.toString(),
              decoration: const InputDecoration(labelText: "Сумма"),
              keyboardType: TextInputType.number,
              validator: (v) =>
              (double.tryParse(v ?? "") == null) ? "Введите число" : null,
              onChanged: (v) => amount = double.tryParse(v) ?? 0,
            ),

            const SizedBox(height: 16),

            TextFormField(
              initialValue: comment,
              decoration: const InputDecoration(labelText: "Комментарий"),
              onChanged: (v) => comment = v,
            ),

            const SizedBox(height: 16),

            categoriesAsync.when(
              data: (categories) {
                return DropdownButtonFormField<String>(
                  value: categoryId,
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

            const SizedBox(height: 8),

            TextButton(
              onPressed: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (_) => _AddCategoryDialog(type: type),
                );

                if (name != null && name.isNotEmpty) {
                  final addCategory = ref.read(addCategoryProvider);
                  await addCategory(name);

                  ref.invalidate(categoriesProvider);
                }
              },
              child: const Text("Добавить категорию"),
            ),

            const SizedBox(height: 8),

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

            FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                await updateTransaction(
                  id: widget.transaction.id,
                  type: type,
                  amount: amount,
                  date: date.toIso8601String().substring(0, 10),
                  comment: comment,
                  categoryId: categoryId
                );

                Navigator.pop(context);
              },
              child: const Text("Сохранить"),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  final String type;

  const _AddCategoryDialog({required this.type});

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
            Navigator.pop(context, name.trim());
          },
          child: const Text("Добавить"),
        ),
      ],
    );
  }
}
