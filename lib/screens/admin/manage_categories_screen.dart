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
                subtitle: Text(
                  _sizeTypeLabel(cat.sizeType),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
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

  String _sizeTypeLabel(SizeType t) {
    switch (t) {
      case SizeType.clothes:
        return 'ملابس';
      case SizeType.shoes:
        return 'أحذية';
      case SizeType.abayas:
        return 'عبايات';
      case SizeType.kids:
        return 'أطفال';
      case SizeType.bags:
        return 'حقائب';
      case SizeType.none:
        return 'بدون مقاس';
    }
  }

  void _showAddEditDialog(BuildContext context, {CategoryModel? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final iconController = TextEditingController(text: category?.icon ?? '');
    SizeType selectedSizeType = category?.sizeType ?? SizeType.clothes;

    final sizeTypeLabels = {
      SizeType.clothes: 'ملابس (XS-XXXL)',
      SizeType.shoes: 'أحذية (30-50)',
      SizeType.abayas: 'عبايات (52-62)',
      SizeType.kids: 'أطفال (حسب العمر)',
      SizeType.bags: 'حقائب (ميني/وسط/كبير)',
      SizeType.none: 'بدون مقاس',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
              const SizedBox(height: 12),
              DropdownButtonFormField<SizeType>(
                value: selectedSizeType,
                decoration: const InputDecoration(labelText: 'نوع المقاسات'),
                isExpanded: true,
                items: SizeType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(sizeTypeLabels[t] ?? t.name),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedSizeType = v);
                  }
                },
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
                      category.id, {
                    'name': name,
                    'icon': icon,
                    'sizeType': selectedSizeType.name,
                  });
                } else {
                  await FirestoreService().createCategory(
                    name: name,
                    icon: icon.isEmpty ? '📦' : icon,
                    sizeType: selectedSizeType.name,
                  );
                }
                if (ctx.mounted) ctx.pop();
              },
              child: const Text(AppStrings.save),
            ),
          ],
        ),
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
