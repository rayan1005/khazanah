import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/image_utils.dart';
import '../../models/brand_model.dart';
import '../../providers/brand_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class ManageBrandsScreen extends ConsumerWidget {
  const ManageBrandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.manageBrands),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
      body: brandsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (brands) {
          if (brands.isEmpty) {
            return const Center(child: Text('لا توجد ماركات'));
          }
          return ListView.builder(
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: brand.imageUrl != null && brand.imageUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(brand.imageUrl!)
                      : null,
                  child: brand.imageUrl == null || brand.imageUrl!.isEmpty
                      ? Text(
                          brand.name.isNotEmpty ? brand.name[0] : '?',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                title: Text(brand.name),
                subtitle: brand.imageUrl != null && brand.imageUrl!.isNotEmpty
                    ? const Text('يحتوي على صورة', style: TextStyle(fontSize: 11, color: AppColors.textHint))
                    : const Text('بدون صورة', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () =>
                          _showAddEditDialog(context, brand: brand),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          size: 20, color: Colors.red),
                      onPressed: () => _deleteBrand(context, brand.id),
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

  void _showAddEditDialog(BuildContext context, {BrandModel? brand}) {
    final nameController = TextEditingController(text: brand?.name ?? '');
    XFile? selectedImage;
    String? currentImageUrl = brand?.imageUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(brand != null ? 'تعديل الماركة' : 'إضافة ماركة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image preview with upload button
                GestureDetector(
                  onTap: () async {
                    final file = await ImageUtils.pickFromGallery();
                    if (file != null) {
                      setDialogState(() {
                        selectedImage = file;
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                        child: ClipOval(
                          child: _buildImagePreview(
                            selectedImage,
                            currentImageUrl,
                            nameController.text,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط لاختيار صورة',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الماركة',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('جاري رفع الصورة...'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => ctx.pop(),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      String? imageUrl = currentImageUrl;

                      // Upload new image if selected
                      if (selectedImage != null) {
                        setDialogState(() => isUploading = true);
                        try {
                          // Create or get brand ID
                          String brandId;
                          if (brand != null) {
                            brandId = brand.id;
                          } else {
                            // Create brand first to get ID
                            brandId = DateTime.now().millisecondsSinceEpoch.toString();
                          }
                          
                          imageUrl = await StorageService().uploadBrandImage(
                            brandId,
                            selectedImage!,
                          );
                          
                          if (brand != null) {
                            await FirestoreService().updateBrand(brand.id, {
                              'name': name,
                              'imageUrl': imageUrl,
                            });
                          } else {
                            await FirestoreService().createBrandWithId(
                              id: brandId,
                              name: name,
                              imageUrl: imageUrl,
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('خطأ: $e')),
                            );
                          }
                          setDialogState(() => isUploading = false);
                          return;
                        }
                      } else {
                        // No new image, just update/create
                        if (brand != null) {
                          await FirestoreService().updateBrand(brand.id, {
                            'name': name,
                            'imageUrl': imageUrl,
                          });
                        } else {
                          await FirestoreService().createBrand(
                            name: name,
                            imageUrl: imageUrl,
                          );
                        }
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

  Widget _buildImagePreview(XFile? selectedImage, String? currentImageUrl, String name) {
    if (selectedImage != null) {
      return FutureBuilder<List<int>>(
        future: selectedImage.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data! as dynamic,
              fit: BoxFit.cover,
              width: 100,
              height: 100,
            );
          }
          return _buildFallbackAvatar(name);
        },
      );
    } else if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: currentImageUrl,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorWidget: (_, __, ___) => _buildFallbackAvatar(name),
      );
    }
    return _buildFallbackAvatar(name);
  }

  Widget _buildFallbackAvatar(String name) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  void _deleteBrand(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الماركة'),
        content: const Text('هل أنت متأكد؟ لن تتمكن من التراجع.'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              await FirestoreService().deleteBrand(id);
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
