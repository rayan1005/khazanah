import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../models/home_section_model.dart';
import '../../providers/home_content_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/storage_service.dart';

class ManageHomeSectionsScreen extends ConsumerStatefulWidget {
  const ManageHomeSectionsScreen({super.key});

  @override
  ConsumerState<ManageHomeSectionsScreen> createState() => _ManageHomeSectionsScreenState();
}

class _ManageHomeSectionsScreenState extends ConsumerState<ManageHomeSectionsScreen> {
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(homeSectionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأقسام'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isReordering ? Icons.check : Icons.reorder),
            onPressed: () => setState(() => _isReordering = !_isReordering),
            tooltip: _isReordering ? 'تم' : 'إعادة الترتيب',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة قسم'),
      ),
      body: sectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (sections) {
          if (sections.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_module_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('لا توجد أقسام', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          if (_isReordering) {
            return ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sections.length,
              onReorder: (oldIndex, newIndex) => _onReorder(sections, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final section = sections[index];
                return _SectionReorderTile(key: ValueKey(section.id), section: section);
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return _SectionCard(
                section: section,
                onEdit: () => _showAddEditDialog(context, section: section),
                onDelete: () => _deleteSection(section),
                onToggle: () => _toggleSection(section),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onReorder(List<HomeSectionModel> sections, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final List<String> orderedIds = sections.map((s) => s.id).toList();
    final item = orderedIds.removeAt(oldIndex);
    orderedIds.insert(newIndex, item);
    await ref.read(firestoreServiceProvider).reorderHomeSections(orderedIds);
  }

  Future<void> _showAddEditDialog(BuildContext context, {HomeSectionModel? section}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditSectionScreen(section: section),
      ),
    );
  }

  Future<void> _deleteSection(HomeSectionModel section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف القسم'),
        content: Text('هل تريد حذف "${section.title}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(firestoreServiceProvider).deleteHomeSection(section.id);
    }
  }

  Future<void> _toggleSection(HomeSectionModel section) async {
    await ref.read(firestoreServiceProvider).updateHomeSection(
      section.id,
      {'isActive': !section.isActive},
    );
  }
}

class _SectionReorderTile extends StatelessWidget {
  final HomeSectionModel section;

  const _SectionReorderTile({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${section.items.length}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: Text(section.title),
        subtitle: Text('${section.typeLabel} • ${section.layoutLabel}', style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.drag_handle),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final HomeSectionModel section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _SectionCard({
    required this.section,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: section.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    section.isActive ? 'مفعل' : 'معطل',
                    style: TextStyle(
                      fontSize: 12,
                      color: section.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(label: section.typeLabel),
                const SizedBox(width: 8),
                _InfoChip(label: section.layoutLabel),
                const SizedBox(width: 8),
                _InfoChip(label: '${section.items.length} عنصر'),
              ],
            ),
            const SizedBox(height: 12),
            
            // Items preview
            if (section.items.isNotEmpty)
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: section.items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final item = section.items[index];
                    return Container(
                      width: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.shimmerBase,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                item.name.isNotEmpty ? item.name[0] : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                    );
                  },
                ),
              ),
            
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    section.isActive ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: onToggle,
                  tooltip: section.isActive ? 'تعطيل' : 'تفعيل',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                  onPressed: onEdit,
                  tooltip: 'تعديل',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: AppColors.primary),
      ),
    );
  }
}

// Full screen for editing section with items
class _EditSectionScreen extends ConsumerStatefulWidget {
  final HomeSectionModel? section;

  const _EditSectionScreen({this.section});

  @override
  ConsumerState<_EditSectionScreen> createState() => _EditSectionScreenState();
}

class _EditSectionScreenState extends ConsumerState<_EditSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late SectionType _type;
  late SectionLayout _layout;
  late bool _isActive;
  late bool _showViewAll;
  late List<SectionItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section?.title ?? '');
    _subtitleController = TextEditingController(text: widget.section?.subtitle ?? '');
    _type = widget.section?.type ?? SectionType.styles;
    _layout = widget.section?.layout ?? SectionLayout.grid2;
    _isActive = widget.section?.isActive ?? true;
    _showViewAll = widget.section?.showViewAll ?? false;
    _items = List.from(widget.section?.items ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section == null ? 'إضافة قسم' : 'تعديل القسم'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('حفظ'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان القسم',
                hintText: 'مثال: تسوق حسب الستايل',
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),

            // Subtitle
            TextFormField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
              ),
            ),
            const SizedBox(height: 12),

            // Type & Layout
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<SectionType>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'النوع'),
                    items: SectionType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(_getTypeLabel(t)));
                    }).toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<SectionLayout>(
                    value: _layout,
                    decoration: const InputDecoration(labelText: 'التخطيط'),
                    items: SectionLayout.values.map((l) {
                      return DropdownMenuItem(value: l, child: Text(_getLayoutLabel(l)));
                    }).toList(),
                    onChanged: (v) => setState(() => _layout = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Switches
            SwitchListTile(
              title: const Text('مفعل'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('إظهار زر "عرض الكل"'),
              value: _showViewAll,
              onChanged: (v) => setState(() => _showViewAll = v),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(height: 32),

            // Items section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'العناصر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة عنصر'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'لا توجد عناصر\nاضغط على "إضافة عنصر" للبدء',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                onReorder: _reorderItems,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _ItemTile(
                    key: ValueKey('item_$index'),
                    item: item,
                    onEdit: () => _editItem(index),
                    onDelete: () => _deleteItem(index),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(SectionType type) {
    switch (type) {
      case SectionType.styles:
        return 'ستايلات';
      case SectionType.brands:
        return 'ماركات';
      case SectionType.categories:
        return 'فئات';
      case SectionType.featured:
        return 'مميزة';
    }
  }

  String _getLayoutLabel(SectionLayout layout) {
    switch (layout) {
      case SectionLayout.grid2:
        return 'شبكة (2)';
      case SectionLayout.grid3:
        return 'شبكة (3)';
      case SectionLayout.horizontal:
        return 'أفقي';
      case SectionLayout.vertical:
        return 'عمودي';
    }
  }

  void _reorderItems(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  Future<void> _addItem() async {
    final result = await showModalBottomSheet<SectionItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditItemSheet(
        sectionId: widget.section?.id ?? const Uuid().v4(),
        itemIndex: _items.length,
      ),
    );

    if (result != null) {
      setState(() => _items.add(result));
    }
  }

  Future<void> _editItem(int index) async {
    final result = await showModalBottomSheet<SectionItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditItemSheet(
        item: _items[index],
        sectionId: widget.section?.id ?? const Uuid().v4(),
        itemIndex: index,
      ),
    );

    if (result != null) {
      setState(() => _items[index] = result);
    }
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(firestoreServiceProvider);
      final section = HomeSectionModel(
        id: widget.section?.id ?? '',
        type: _type,
        layout: _layout,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
        items: _items,
        order: widget.section?.order ?? 999,
        isActive: _isActive,
        showViewAll: _showViewAll,
        createdAt: widget.section?.createdAt ?? DateTime.now(),
      );

      if (widget.section == null) {
        await service.createHomeSection(section);
      } else {
        await service.updateHomeSection(section.id, section.toMap());
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _ItemTile extends StatelessWidget {
  final SectionItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: AppColors.shimmerBase,
                  child: Center(
                    child: Text(
                      item.name.isNotEmpty ? item.name[0] : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
        ),
        title: Text(item.name),
        subtitle: Text(item.filterQuery, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: onDelete,
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }
}

class _EditItemSheet extends StatefulWidget {
  final SectionItem? item;
  final String sectionId;
  final int itemIndex;

  const _EditItemSheet({
    this.item,
    required this.sectionId,
    required this.itemIndex,
  });

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _filterQueryController;
  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _filterQueryController = TextEditingController(text: widget.item?.filterQuery ?? '');
    _existingImageUrl = widget.item?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _filterQueryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.item == null ? 'إضافة عنصر' : 'تعديل العنصر',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: _selectedImage != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedImage != null
                              ? FutureBuilder<List<int>>(
                                  future: _selectedImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data! as dynamic,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      );
                                    }
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                )
                              : CachedNetworkImage(
                                  imageUrl: _existingImageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: AppColors.primary),
                            const SizedBox(height: 8),
                            Text('اضغط لرفع صورة', style: TextStyle(color: AppColors.primary)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  hintText: 'مثال: Romance ready',
                ),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),

              // Filter query
              TextFormField(
                controller: _filterQueryController,
                decoration: const InputDecoration(
                  labelText: 'فلتر البحث',
                  hintText: 'مثال: ?style=romantic',
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.item == null ? 'إضافة' : 'حفظ التغييرات'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final file = await ImageUtils.pickFromGallery();
    if (file != null) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String imageUrl = _existingImageUrl ?? '';

      // Upload image if new file selected
      if (_selectedImage != null) {
        imageUrl = await StorageService().uploadSectionItemImage(
          widget.sectionId,
          widget.itemIndex,
          _selectedImage!,
        );
      }

      final item = SectionItem(
        name: _nameController.text.trim(),
        imageUrl: imageUrl,
        filterQuery: _filterQueryController.text.trim(),
      );

      if (mounted) Navigator.pop(context, item);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
