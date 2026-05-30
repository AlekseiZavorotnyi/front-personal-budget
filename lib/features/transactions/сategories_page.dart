import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category_model.dart';
import 'categories_providers.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Категории")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<String>(
            context: context,
            builder: (_) => const _EditCategoryDialog(),
          );

          if (result != null) {
            final addCategory = ref.read(addCategoryProvider);
            await addCategory(result);
            ref.invalidate(categoriesProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final c = list[i];
            return ListTile(
              title: Text(c.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (_) => _EditCategoryDialog(
                          category: c,
                        ),
                      );

                      if (result != null) {
                        final updateCategory = ref.read(updateCategoryProvider);
                        await updateCategory(
                          id: c.id,
                          name: result,
                        );
                        ref.invalidate(categoriesProvider);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Удалить категорию?"),
                          content: const Text(
                            "Транзакции останутся, но categoryId станет null.",
                          ),
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
                        await deleteCategory(c.id);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Text("Ошибка загрузки категорий"),
      ),
    );
  }
}

class _EditCategoryDialog extends StatefulWidget {
  final CategoryModel? category;

  const _EditCategoryDialog({this.category});

  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.category?.name ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? "Новая категория" : "Редактировать категорию"),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: "Название",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isEmpty) return;

            Navigator.pop(context, controller.text.trim());
          },
          child: const Text("Сохранить"),
        ),
      ],
    );
  }
}
