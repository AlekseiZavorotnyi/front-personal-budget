import 'package:dio/dio.dart';
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
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

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
      final responseData = error.response?.data;

      if (responseData is Map && responseData['message'] != null) {
        return responseData['message'].toString();
      }

      return error.message ?? "Не удалось добавить транзакцию";
    }

    return "Не удалось добавить транзакцию";
  }
}
