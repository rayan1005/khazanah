import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../services/firestore_service.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.manageCategories),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('لا توجد تصنيفات'));
          }
          return ReorderableListView.builder(
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;
              final item = categories[oldIndex];
              await FirestoreService()
                  .updateCategory(item.id, {'order': newIndex});
            },
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                key: ValueKey(cat.id),
                leading: Text(cat.icon, style: const TextStyle(fontSize: 24)),
                title: Text(cat.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () =>
                          _showAddEditDialog(context, category: cat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteCategory(context, cat.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {CategoryModel? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final iconController = TextEditingController(text: category?.icon ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category != null ? 'تعديل التصنيف' : 'إضافة تصنيف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم التصنيف'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                  labelText: 'أيقونة (إيموجي)', hintText: '👕'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final icon = iconController.text.trim();
              if (name.isEmpty) return;

              if (category != null) {
                await FirestoreService().updateCategory(
                    category.id, {'name': name, 'icon': icon});
              } else {
                await FirestoreService().createCategory(
                  name: name,
                  icon: icon.isEmpty ? '📦' : icon,
                );
              }
              if (ctx.mounted) ctx.pop();
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التصنيف'),
        content: const Text('هل أنت متأكد؟ لن تتمكن من التراجع.'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              await FirestoreService().deleteCategory(id);
              if (ctx.mounted) ctx.pop();
            },
            child: const Text(AppStrings.delete,
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
