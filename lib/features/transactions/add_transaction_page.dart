import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_personal_budget/features/transactions/transactions_providers.dart';
import 'package:go_router/go_router.dart';


class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  String type = "expense";
  double amount = 0;
  String comment = "";
  DateTime date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final addTransaction = ref.watch(addTransactionProvider);

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
                decoration: const InputDecoration(labelText: "Сумма"),
                keyboardType: TextInputType.number,
                validator: (v) =>
                (double.tryParse(v ?? "") == null) ? "Введите число" : null,
                onChanged: (v) => amount = double.tryParse(v) ?? 0,
              ),

              const SizedBox(height: 16),

              TextFormField(
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

                  await addTransaction(
                    type: type,
                    amount: amount,
                    date: date.toIso8601String().substring(0, 10),
                    comment: comment,
                  );

                  context.pop();
                },
                child: const Text("Добавить"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
