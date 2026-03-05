import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/saudi_cities.dart';
import '../../core/constants/sizes.dart';
import '../../models/category_model.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/permission_utils.dart';
import '../../core/utils/image_utils.dart';
import '../../models/post_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../providers/app_settings_provider.dart';

class AddPostScreen extends ConsumerStatefulWidget {
  final String? editPostId;
  const AddPostScreen({super.key, this.editPostId});

  @override
  ConsumerState<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends ConsumerState<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _purchasePriceController = TextEditingController();

  List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = []; // For editing
  String? _category;
  String? _brand;
  String? _size;
  String? _color;
  String? _condition;
  String? _gender;
  String? _city;
  bool _negotiable = false;
  bool _isLoading = false;
  bool _allowChat = true;
  bool _allowWhatsapp = false;
  bool _commentsEnabled = true;

  bool get isEditing => widget.editPostId != null;

  final _conditions = [
    AppStrings.conditionNewWithTag,
    AppStrings.conditionNew,
    AppStrings.conditionLikeNew,
    AppStrings.conditionUsedClean,
    AppStrings.conditionUsed,
  ];

  final _genders = [
    AppStrings.women,
    AppStrings.men,
    AppStrings.unisex,
    AppStrings.kids,
  ];

  final _colors = [
    AppStrings.colorBlack,
    AppStrings.colorWhite,
    AppStrings.colorRed,
    AppStrings.colorBlue,
    AppStrings.colorBeige,
    AppStrings.colorBrown,
    AppStrings.colorGray,
    AppStrings.colorPink,
    AppStrings.colorGreen,
    AppStrings.colorOrange,
    AppStrings.colorYellow,
    AppStrings.colorPurple,
    AppStrings.colorMulti,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load user city as default
    final userProfile = await ref.read(authServiceProvider).getCurrentUserProfile();
    if (userProfile != null && mounted) {
      setState(() => _city = userProfile.city);
    }

    // If editing, load the post data
    if (isEditing) {
      final post = await ref.read(firestoreServiceProvider).getPost(widget.editPostId!);
      if (post != null && mounted) {
        setState(() {
          _titleController.text = post.title;
          _descController.text = post.description;
          _priceController.text = post.price.toStringAsFixed(0);
          _category = post.category;
          _brand = post.brand;
          _size = post.size;
          _color = post.color;
          _condition = post.condition;
          _gender = post.gender;
          _city = post.city;
          _negotiable = post.negotiable;
          _allowChat = post.allowChat;
          _allowWhatsapp = post.allowWhatsapp;
          _commentsEnabled = post.commentsEnabled;
          _existingImageUrls = List.from(post.photos);
          if (post.purchasePrice != null) {
            _purchasePriceController.text = post.purchasePrice!.toStringAsFixed(0);
          }
        });
      }
    } else {
      // Load draft if available
      _loadDraft();
    }
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString('post_draft');
      if (draftJson != null) {
        final draft = jsonDecode(draftJson) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _titleController.text = draft['title'] ?? '';
            _descController.text = draft['description'] ?? '';
            _priceController.text = draft['price'] ?? '';
            _category = draft['category'];
            _brand = draft['brand'];
            _size = draft['size'];
            _color = draft['color'];
            _condition = draft['condition'];
            _gender = draft['gender'];
            _negotiable = draft['negotiable'] ?? false;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = {
        'title': _titleController.text,
        'description': _descController.text,
        'price': _priceController.text,
        'category': _category,
        'brand': _brand,
        'size': _size,
        'color': _color,
        'condition': _condition,
        'gender': _gender,
        'negotiable': _negotiable,
      };
      await prefs.setString('post_draft', jsonEncode(draft));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.draftSaved)),
        );
      }
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('post_draft');
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length + _existingImageUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى 5 صور')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('التقاط صورة'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final hasPermission =
                      await PermissionUtils.requestCamera(context);
                  if (!hasPermission) return;
                  final image = await ImageUtils.pickFromCamera();
                  if (image != null && mounted) {
                    setState(() => _selectedImages.add(image));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('اختيار من المعرض'),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!kIsWeb) {
                    await PermissionUtils.requestPhotos(context);
                  }
                  final remaining =
                      5 - _selectedImages.length - _existingImageUrls.length;
                  final images = await ImageUtils.pickMultipleFromGallery(
                    maxImages: remaining,
                  );
                  if (images.isNotEmpty && mounted) {
                    setState(() => _selectedImages.addAll(images));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف صورة واحدة على الأقل')),
      );
      return;
    }
    if (_category == null || _brand == null || _size == null ||
        _color == null || _condition == null || _gender == null || _city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أكمل جميع الحقول المطلوبة')),
      );
      return;
    }

    // At least one contact method must be selected
    if (!_allowChat && !_allowWhatsapp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر طريقة تواصل واحدة على الأقل')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final service = ref.read(firestoreServiceProvider);
      final storageService = StorageService();

      List<String> photoUrls = List.from(_existingImageUrls);

      // Upload new images
      if (_selectedImages.isNotEmpty) {
        final postId = isEditing
            ? widget.editPostId!
            : DateTime.now().millisecondsSinceEpoch.toString();
        final newUrls =
            await storageService.uploadPostImages(postId, _selectedImages);
        photoUrls.addAll(newUrls);
      }

      if (isEditing) {
        await service.updatePost(widget.editPostId!, {
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'photos': photoUrls,
          'category': _category,
          'brand': _brand,
          'size': _size,
          'color': _color,
          'condition': _condition,
          'price': double.parse(_priceController.text),
          'purchasePrice': _purchasePriceController.text.trim().isNotEmpty
              ? double.parse(_purchasePriceController.text)
              : null,
          'negotiable': _negotiable,
          'city': _city,
          'gender': _gender,
          'allowChat': _allowChat,
          'allowWhatsapp': _allowWhatsapp,
          'commentsEnabled': _commentsEnabled,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.postUpdated)),
          );
        }
      } else {
        final post = PostModel(
          postId: '',
          userId: uid,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          photos: photoUrls,
          category: _category!,
          brand: _brand!,
          size: _size!,
          color: _color!,
          condition: _condition!,
          price: double.parse(_priceController.text),
          purchasePrice: _purchasePriceController.text.trim().isNotEmpty
              ? double.parse(_purchasePriceController.text)
              : null,
          negotiable: _negotiable,
          city: _city!,
          gender: _gender!,
          allowChat: _allowChat,
          allowWhatsapp: _allowWhatsapp,
          commentsEnabled: _commentsEnabled,
          createdAt: DateTime.now(),
        );
        await service.createPost(post);
        await _clearDraft();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.postPublished)),
          );
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final brandsAsync = ref.watch(brandsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppStrings.editPost : AppStrings.addPost),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!isEditing)
            TextButton(
              onPressed: _saveDraft,
              child: const Text(AppStrings.saveDraft),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photos section
            const Text(AppStrings.addPhotos,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            const Text(AppStrings.maxPhotos,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Existing images
                  ..._existingImageUrls.asMap().entries.map((entry) {
                    return _imagePreview(
                      child: Image.network(entry.value, fit: BoxFit.cover),
                      onRemove: () {
                        setState(() => _existingImageUrls.removeAt(entry.key));
                      },
                    );
                  }),
                  // Selected images
                  ..._selectedImages.asMap().entries.map((entry) {
                    return _imagePreview(
                      child: kIsWeb
                          ? FutureBuilder(
                              future: entry.value.readAsBytes(),
                              builder: (_, snap) {
                                if (snap.hasData) {
                                  return Image.memory(snap.data!,
                                      fit: BoxFit.cover);
                                }
                                return const SizedBox.shrink();
                              },
                            )
                          : Image.file(File(entry.value.path),
                              fit: BoxFit.cover),
                      onRemove: () {
                        setState(() => _selectedImages.removeAt(entry.key));
                      },
                    );
                  }),
                  // Add button
                  if (_selectedImages.length + _existingImageUrls.length < 5)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.divider,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 32, color: AppColors.textHint),
                            SizedBox(height: 4),
                            Text('إضافة',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textHint)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Photo warning text from app settings
            Consumer(
              builder: (context, ref, _) {
                final settingsAsync = ref.watch(appSettingsStreamProvider);
                return settingsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (settings) {
                    if (settings.photoWarningText.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              settings.photoWarningText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleController,
              validator: Validators.validateTitle,
              decoration: const InputDecoration(
                labelText: AppStrings.title,
                hintText: AppStrings.titleHint,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              validator: Validators.validateDescription,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.description,
                hintText: AppStrings.descriptionHint,
              ),
            ),
            const SizedBox(height: 16),

            // Category dropdown
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (categories) => DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: AppStrings.category),
                isExpanded: true,
                items: categories
                    .map((c) =>
                        DropdownMenuItem(value: c.name, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _category = v;
                  _size = null; // Reset size when category changes
                }),
                validator: (v) => v == null ? 'اختر الفئة' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Brand dropdown
            brandsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (brands) => DropdownButtonFormField<String>(
                value: _brand,
                decoration: const InputDecoration(labelText: AppStrings.brand),
                isExpanded: true,
                items: brands
                    .map((b) =>
                        DropdownMenuItem(value: b.name, child: Text(b.name)))
                    .toList(),
                onChanged: (v) => setState(() => _brand = v),
                validator: (v) => v == null ? 'اختر الماركة' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Size + Color row
            Row(
              children: [
                Expanded(
                  child: categoriesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (categories) {
                      final selectedCat = categories.where((c) => c.name == _category).firstOrNull;
                      final sizeType = selectedCat?.sizeType ?? SizeType.clothes;
                      final sizes = Sizes.forSizeType(sizeType);
                      
                      // If no sizes for this category, show placeholder
                      if (sizes.isEmpty) {
                        return DropdownButtonFormField<String>(
                          value: 'مقاس موحد',
                          decoration: const InputDecoration(labelText: AppStrings.size),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'مقاس موحد', child: Text('مقاس موحد')),
                          ],
                          onChanged: (v) => setState(() => _size = v),
                        );
                      }
                      
                      return DropdownButtonFormField<String>(
                        value: sizes.contains(_size) ? _size : null,
                        decoration: const InputDecoration(labelText: AppStrings.size),
                        isExpanded: true,
                        items: sizes
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _size = v),
                        validator: (v) => v == null ? 'اختر المقاس' : null,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _color,
                    decoration:
                        const InputDecoration(labelText: AppStrings.color),
                    isExpanded: true,
                    items: _colors
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _color = v),
                    validator: (v) => v == null ? 'اختر اللون' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Condition
            DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(labelText: AppStrings.condition),
              isExpanded: true,
              items: _conditions
                  .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _condition = v),
              validator: (v) => v == null ? 'اختر الحالة' : null,
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: AppStrings.gender),
              isExpanded: true,
              items: _genders
                  .map(
                      (g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => v == null ? 'اختر القسم' : null,
            ),
            const SizedBox(height: 16),

            // Price + Negotiable
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    validator: Validators.validatePrice,
                    decoration: const InputDecoration(
                      labelText: AppStrings.price,
                      hintText: AppStrings.priceHint,
                      suffixText: 'ر.س',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _purchasePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'سعر الشراء',
                      hintText: 'اختياري',
                      suffixText: 'ر.س',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: _negotiable,
                  onChanged: (v) => setState(() => _negotiable = v),
                  activeColor: AppColors.primary,
                ),
                const Text(AppStrings.negotiable,
                    style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),

            // City
            DropdownButtonFormField<String>(
              value: _city,
              decoration:
                  const InputDecoration(labelText: AppStrings.selectCity),
              isExpanded: true,
              items: SaudiCities.cities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _city = v),
              validator: (v) => v == null ? 'اختر المدينة' : null,
            ),
            const SizedBox(height: 24),

            // Contact method
            const Text(
              'طريقة التواصل',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'اختر طريقة أو أكثر للتواصل الخاص (يجب اختيار واحدة على الأقل):',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // Don't allow deselecting if it's the only one selected
                        if (_allowChat && !_allowWhatsapp) return;
                        _allowChat = !_allowChat;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _allowChat
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _allowChat
                              ? AppColors.primary
                              : AppColors.divider,
                          width: _allowChat ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: _allowChat
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'عبر التطبيق',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _allowChat
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (_allowChat)
                            Icon(Icons.check_circle,
                                size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // Don't allow deselecting if it's the only one selected
                        if (_allowWhatsapp && !_allowChat) return;
                        _allowWhatsapp = !_allowWhatsapp;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _allowWhatsapp
                            ? AppColors.whatsapp.withValues(alpha: 0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _allowWhatsapp
                              ? AppColors.whatsapp
                              : AppColors.divider,
                          width: _allowWhatsapp ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat,
                            color: _allowWhatsapp
                                ? AppColors.whatsapp
                                : AppColors.textSecondary,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'واتساب',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _allowWhatsapp
                                  ? AppColors.whatsapp
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (_allowWhatsapp)
                            Icon(Icons.check_circle,
                                size: 16, color: AppColors.whatsapp),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Comments toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.comment_outlined,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التعليقات',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'السماح للآخرين بالتعليق على الإعلان',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _commentsEnabled,
                    onChanged: (v) => setState(() => _commentsEnabled = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Publish
            ElevatedButton(
              onPressed: _isLoading ? null : _publish,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEditing ? AppStrings.editPost : AppStrings.publishPost),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview({required Widget child, required VoidCallback onRemove}) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(left: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.expand(child: child),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
