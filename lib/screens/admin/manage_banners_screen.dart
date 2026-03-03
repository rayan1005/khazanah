import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../models/banner_model.dart';
import '../../providers/home_content_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/storage_service.dart';

class ManageBannersScreen extends ConsumerStatefulWidget {
  const ManageBannersScreen({super.key});

  @override
  ConsumerState<ManageBannersScreen> createState() => _ManageBannersScreenState();
}

class _ManageBannersScreenState extends ConsumerState<ManageBannersScreen> {
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة البانرات'),
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
        label: const Text('إضافة بانر'),
      ),
      body: bannersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (banners) {
          if (banners.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('لا توجد بانرات', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          if (_isReordering) {
            return ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: banners.length,
              onReorder: (oldIndex, newIndex) => _onReorder(banners, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final banner = banners[index];
                return _BannerReorderTile(key: ValueKey(banner.id), banner: banner);
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _BannerCard(
                banner: banner,
                onEdit: () => _showAddEditDialog(context, banner: banner),
                onDelete: () => _deleteBanner(banner),
                onToggle: () => _toggleBanner(banner),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onReorder(List<BannerModel> banners, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final List<String> orderedIds = banners.map((b) => b.id).toList();
    final item = orderedIds.removeAt(oldIndex);
    orderedIds.insert(newIndex, item);
    await ref.read(firestoreServiceProvider).reorderBanners(orderedIds);
  }

  Future<void> _showAddEditDialog(BuildContext context, {BannerModel? banner}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddEditBannerSheet(
        banner: banner,
        onSave: (newBanner, imageFile) async {
          await _saveBanner(newBanner, imageFile);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _saveBanner(BannerModel banner, XFile? imageFile) async {
    final service = ref.read(firestoreServiceProvider);
    
    String imageUrl = banner.imageUrl;
    
    // Upload image if new file selected
    if (imageFile != null) {
      final bannerId = banner.id.isEmpty ? const Uuid().v4() : banner.id;
      imageUrl = await StorageService().uploadBannerImage(bannerId, imageFile);
      
      if (banner.id.isEmpty) {
        // Create new banner with uploaded image
        await service.createBannerWithId(
          bannerId,
          banner.copyWith(id: bannerId, imageUrl: imageUrl),
        );
        return;
      }
    }

    if (banner.id.isEmpty) {
      // Create new banner
      await service.createBanner(banner.copyWith(imageUrl: imageUrl));
    } else {
      // Update existing banner
      await service.updateBanner(banner.id, banner.copyWith(imageUrl: imageUrl).toMap());
    }
  }

  Future<void> _deleteBanner(BannerModel banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف البانر'),
        content: Text('هل تريد حذف "${banner.title}"؟'),
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
      await StorageService().deleteBannerImage(banner.id);
      await ref.read(firestoreServiceProvider).deleteBanner(banner.id);
    }
  }

  Future<void> _toggleBanner(BannerModel banner) async {
    await ref.read(firestoreServiceProvider).updateBanner(
      banner.id,
      {'isActive': !banner.isActive},
    );
  }
}

class _BannerReorderTile extends StatelessWidget {
  final BannerModel banner;

  const _BannerReorderTile({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: banner.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  width: 60,
                  height: 40,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 60,
                  height: 40,
                  color: AppColors.shimmerBase,
                  child: const Icon(Icons.image, color: AppColors.textHint),
                ),
        ),
        title: Text(banner.title),
        subtitle: Text(banner.typeLabel, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.drag_handle),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: banner.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.shimmerBase,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  )
                : Container(
                    color: AppColors.shimmerBase,
                    child: const Center(
                      child: Icon(Icons.image, size: 48, color: AppColors.textHint),
                    ),
                  ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        banner.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: banner.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        banner.isActive ? 'مفعل' : 'معطل',
                        style: TextStyle(
                          fontSize: 12,
                          color: banner.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (banner.subtitle != null && banner.subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      banner.subtitle!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        banner.typeLabel,
                        style: TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        banner.isActive ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: onToggle,
                      tooltip: banner.isActive ? 'تعطيل' : 'تفعيل',
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
        ],
      ),
    );
  }
}

class _AddEditBannerSheet extends StatefulWidget {
  final BannerModel? banner;
  final Future<void> Function(BannerModel banner, XFile? imageFile) onSave;

  const _AddEditBannerSheet({this.banner, required this.onSave});

  @override
  State<_AddEditBannerSheet> createState() => _AddEditBannerSheetState();
}

class _AddEditBannerSheetState extends State<_AddEditBannerSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _actionUrlController;
  late BannerType _type;
  late bool _isActive;
  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.banner?.title ?? '');
    _subtitleController = TextEditingController(text: widget.banner?.subtitle ?? '');
    _actionUrlController = TextEditingController(text: widget.banner?.actionUrl ?? '');
    _type = widget.banner?.type ?? BannerType.slider;
    _isActive = widget.banner?.isActive ?? true;
    _existingImageUrl = widget.banner?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _actionUrlController.dispose();
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
                widget.banner == null ? 'إضافة بانر' : 'تعديل البانر',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
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
                            Icon(Icons.add_photo_alternate, size: 48, color: AppColors.primary),
                            const SizedBox(height: 8),
                            Text(
                              'اضغط لرفع صورة',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  hintText: 'مثال: تخفيضات الربيع',
                ),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),

              // Subtitle
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: 'العنوان الفرعي (اختياري)',
                  hintText: 'وصف قصير',
                ),
              ),
              const SizedBox(height: 12),

              // Type dropdown
              DropdownButtonFormField<BannerType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: BannerType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(_getTypeLabel(t)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),

              // Action URL
              TextFormField(
                controller: _actionUrlController,
                decoration: const InputDecoration(
                  labelText: 'رابط العمل (اختياري)',
                  hintText: 'مثال: /search?category=shoes',
                ),
              ),
              const SizedBox(height: 12),

              // Active switch
              SwitchListTile(
                title: const Text('مفعل'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
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
                    : Text(widget.banner == null ? 'إضافة' : 'حفظ التغييرات'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(BannerType type) {
    switch (type) {
      case BannerType.slider:
        return 'سلايدر (متحرك)';
      case BannerType.hero:
        return 'هيرو (صورة كبيرة)';
      case BannerType.promo:
        return 'ترويجي (صغير)';
    }
  }

  Future<void> _pickImage() async {
    final file = await ImageUtils.pickFromGallery();
    if (file != null) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار صورة')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final banner = BannerModel(
        id: widget.banner?.id ?? '',
        type: _type,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
        imageUrl: _existingImageUrl ?? '',
        actionUrl: _actionUrlController.text.trim().isEmpty ? null : _actionUrlController.text.trim(),
        order: widget.banner?.order ?? 999,
        isActive: _isActive,
        createdAt: widget.banner?.createdAt ?? DateTime.now(),
      );

      await widget.onSave(banner, _selectedImage);
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
