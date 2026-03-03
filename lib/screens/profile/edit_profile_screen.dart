import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/saudi_cities.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/validators.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  String? _selectedCity;
  bool _isLoading = false;
  XFile? _newPhoto;

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _pickPhoto() async {
    final photo = await ImageUtils.pickFromGallery();
    if (photo != null) {
      setState(() => _newPhoto = photo);
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String? photoUrl;

      if (_newPhoto != null) {
        final bytes = await _newPhoto!.readAsBytes();
        photoUrl =
            await StorageService().uploadAvatar(uid, bytes);
      }

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'city': _selectedCity,
        'whatsapp': _whatsappController.text.trim().isEmpty
            ? null
            : '+966${_whatsappController.text.trim()}',
      };
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await FirestoreService().updateUser(uid, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));
    }

    final userAsync = ref.watch(userStreamByIdProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          // Initialize fields once
          if (_nameController.text.isEmpty) {
            _nameController.text = user.name;
            _whatsappController.text =
                user.whatsapp?.replaceAll('+966', '') ?? '';
            _selectedCity = user.city;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Photo
                Center(
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: _newPhoto != null
                          ? null // handled by decoration
                          : user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                      child: _newPhoto == null && user.photoUrl == null
                          ? Icon(Icons.camera_alt,
                              size: 32, color: AppColors.primary)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.fullName,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),

                // City
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(
                    labelText: AppStrings.cityLabel,
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: SaudiCities.cities
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedCity = v),
                ),
                const SizedBox(height: 16),

                // WhatsApp
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _whatsappController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.whatsappOptional,
                      prefixIcon: Icon(Icons.chat),
                      prefixText: '+966 ',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(AppStrings.save),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
