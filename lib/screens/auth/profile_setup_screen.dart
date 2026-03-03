import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/saudi_cities.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  String? _selectedCity;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر المدينة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser!;
      final user = UserModel(
        uid: firebaseUser.uid,
        name: _nameController.text.trim(),
        phone: firebaseUser.phoneNumber ?? ref.read(authNotifierProvider).phone,
        whatsapp: _whatsappController.text.trim().isNotEmpty
            ? Validators.formatPhone(_whatsappController.text.trim())
            : null,
        city: _selectedCity!,
        createdAt: DateTime.now(),
      );

      await ref.read(authServiceProvider).saveProfile(user);

      if (mounted) {
        context.go('/home');
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.setupProfile),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // Avatar placeholder
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),

                // Name
                const Text(AppStrings.displayName,
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: Validators.validateName,
                  decoration: const InputDecoration(
                    hintText: AppStrings.displayNameHint,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 20),

                // City
                const Text(AppStrings.selectCity,
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  hint: const Text(AppStrings.selectCity),
                  isExpanded: true,
                  items: SaudiCities.cities.map((city) {
                    return DropdownMenuItem(value: city, child: Text(city));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCity = value);
                  },
                ),
                const SizedBox(height: 20),

                // WhatsApp number (optional)
                const Text(AppStrings.whatsappNumber,
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  'اختياري — سيظهر للمشترين للتواصل معك عبر واتساب',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      hintText: AppStrings.whatsappHint,
                      prefixIcon: Icon(Icons.chat, color: AppColors.whatsapp),
                      prefixText: '+966 ',
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(AppStrings.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
