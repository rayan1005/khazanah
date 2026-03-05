import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../core/utils/permission_utils.dart';

class EditBoutiqueScreen extends ConsumerStatefulWidget {
  const EditBoutiqueScreen({super.key});

  @override
  ConsumerState<EditBoutiqueScreen> createState() => _EditBoutiqueScreenState();
}

class _EditBoutiqueScreenState extends ConsumerState<EditBoutiqueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _snapchatController = TextEditingController();
  final _maaroofController = TextEditingController();

  XFile? _newLogo;
  XFile? _newCover;
  String? _currentLogoUrl;
  String? _currentCoverUrl;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _snapchatController.dispose();
    _maaroofController.dispose();
    super.dispose();
  }

  void _initFromUser() {
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user != null && !_initialized) {
      _nameController.text = user.boutiqueName ?? '';
      _descController.text = user.boutiqueDescription ?? '';
      _instagramController.text = user.instagramUrl ?? '';
      _tiktokController.text = user.tiktokUrl ?? '';
      _snapchatController.text = user.snapchatUrl ?? '';
      _maaroofController.text = user.maaroofUrl ?? '';
      _currentLogoUrl = user.boutiqueLogo;
      _currentCoverUrl = user.boutiqueCover;
      _initialized = true;
    }
  }

  Future<void> _pickCover() async {
    final hasPermission = await PermissionUtils.requestPhotos(context);
    if (!hasPermission) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
    );
    if (image != null) {
      setState(() => _newCover = image);
    }
  }

  Future<void> _pickLogo() async {
    final hasPermission = await PermissionUtils.requestPhotos(context);
    if (!hasPermission) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (image != null) {
      setState(() => _newLogo = image);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final storageService = StorageService();
      final data = <String, dynamic>{};

      // Upload new cover if changed
      if (_newCover != null) {
        final coverUrl =
            await storageService.uploadBoutiqueCover(user.uid, _newCover!);
        data['boutiqueCover'] = coverUrl;
      }

      // Upload new logo if changed
      if (_newLogo != null) {
        final logoUrl =
            await storageService.uploadBoutiqueLogo(user.uid, _newLogo!);
        data['boutiqueLogo'] = logoUrl;
      }

      // Text fields
      data['boutiqueName'] = _nameController.text.trim();
      data['boutiqueDescription'] = _descController.text.trim();

      final instagram = _instagramController.text.trim();
      data['instagramUrl'] = instagram.isNotEmpty ? instagram : null;

      final tiktok = _tiktokController.text.trim();
      data['tiktokUrl'] = tiktok.isNotEmpty ? tiktok : null;

      final snapchat = _snapchatController.text.trim();
      data['snapchatUrl'] = snapchat.isNotEmpty ? snapchat : null;

      final maaroof = _maaroofController.text.trim();
      data['maaroofUrl'] = maaroof.isNotEmpty ? maaroof : null;

      await FirestoreService().updateBoutiqueProfile(user.uid, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث البوتيك بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('$e')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('لم يتم العثور على المستخدم')),
          );
        }

        _initFromUser();

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.editBoutique),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        AppStrings.save,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Cover Image
                GestureDetector(
                  onTap: _pickCover,
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: _newCover != null
                            ? Image.file(File(_newCover!.path),
                                fit: BoxFit.cover)
                            : _currentCoverUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: _currentCoverUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    child: Icon(Icons.panorama,
                                        size: 48, color: AppColors.primary),
                                  ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.2),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt,
                                    size: 32, color: Colors.white),
                                SizedBox(height: 4),
                                Text(
                                  'تغيير صورة الغلاف',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Logo
                Center(
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: GestureDetector(
                      onTap: _pickLogo,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: _newLogo != null
                                  ? FileImage(File(_newLogo!.path))
                                  : _currentLogoUrl != null
                                      ? CachedNetworkImageProvider(
                                          _currentLogoUrl!)
                                      : null,
                              child: (_newLogo == null &&
                                      _currentLogoUrl == null)
                                  ? Icon(Icons.store,
                                      size: 36, color: AppColors.primary)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary,
                              child: const Icon(Icons.camera_alt,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Form fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: AppStrings.boutiqueName,
                          prefixIcon: const Icon(Icons.store),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'أدخل اسم البوتيك'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: AppStrings.boutiqueDescription,
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _instagramController,
                        decoration: InputDecoration(
                          labelText: 'رابط انستقرام',
                          prefixIcon: const Icon(Icons.camera_alt),
                          hintText: 'https://instagram.com/...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tiktokController,
                        decoration: InputDecoration(
                          labelText: 'رابط تيكتوك',
                          prefixIcon: const Icon(Icons.music_note),
                          hintText: 'https://tiktok.com/...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _snapchatController,
                        decoration: InputDecoration(
                          labelText: 'حساب سناب شات',
                          prefixIcon: const Icon(Icons.photo_camera_front),
                          hintText: 'https://snapchat.com/add/...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maaroofController,
                        decoration: InputDecoration(
                          labelText: 'رابط معروف',
                          prefixIcon: const Icon(Icons.verified_user),
                          hintText: 'https://maroof.sa/...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
