import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../transactions/transactions_providers.dart';
import '../../core/models/transaction_model.dart';

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

  @override
  void initState() {
    super.initState();
    type = widget.transaction.type;
    amount = widget.transaction.amount;
    comment = widget.transaction.comment ?? "";
    date = widget.transaction.date;
  }

  @override
  Widget build(BuildContext context) {
    final updateTransaction = ref.watch(updateTransactionProvider);

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
