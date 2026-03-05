import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_settings_provider.dart';
import '../../services/firestore_service.dart';

class ManageAppSettingsScreen extends ConsumerStatefulWidget {
  const ManageAppSettingsScreen({super.key});

  @override
  ConsumerState<ManageAppSettingsScreen> createState() =>
      _ManageAppSettingsScreenState();
}

class _ManageAppSettingsScreenState
    extends ConsumerState<ManageAppSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commissionController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _photoWarningController = TextEditingController();
  final _termsController = TextEditingController();
  final _privacyController = TextEditingController();
  final _supportEmailController = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _commissionController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _photoWarningController.dispose();
    _termsController.dispose();
    _privacyController.dispose();
    _supportEmailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirestoreService().updateAppSettings({
        'commissionRate':
            double.tryParse(_commissionController.text.trim()) ?? 4.0,
        'bankName': _bankNameController.text.trim(),
        'bankAccount': _bankAccountController.text.trim(),
        'photoWarningText': _photoWarningController.text.trim(),
        'termsAndConditions': _termsController.text.trim(),
        'privacyPolicy': _privacyController.text.trim(),
        'supportEmail': _supportEmailController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات التطبيق'),
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
                : Text('حفظ',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (settings) {
          if (!_initialized) {
            _commissionController.text = settings.commissionRate.toString();
            _bankNameController.text = settings.bankName;
            _bankAccountController.text = settings.bankAccount;
            _photoWarningController.text = settings.photoWarningText;
            _termsController.text = settings.termsAndConditions;
            _privacyController.text = settings.privacyPolicy;
            _supportEmailController.text = settings.supportEmail;
            _initialized = true;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Commission
                _SectionHeader(
                    icon: Icons.percent, title: 'العمولة والحساب البنكي'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commissionController,
                  decoration: const InputDecoration(
                    labelText: 'نسبة العمولة (%)',
                    hintText: '4.0',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'مطلوب';
                    final num = double.tryParse(v.trim());
                    if (num == null || num < 0 || num > 100) {
                      return 'أدخل نسبة صحيحة (0-100)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم البنك',
                    hintText: 'مثال: بنك الراجحي',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bankAccountController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الحساب / الآيبان',
                    hintText: 'SA...',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                ),
                const SizedBox(height: 24),

                // Photo Warning
                _SectionHeader(
                    icon: Icons.warning_amber, title: 'تحذير رفع الصور'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _photoWarningController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'نص التحذير',
                    hintText: 'يمنع نشر الصور العارية...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Icon(Icons.warning_amber),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Support
                _SectionHeader(
                    icon: Icons.support_agent, title: 'الدعم والتواصل'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _supportEmailController,
                  decoration: const InputDecoration(
                    labelText: 'بريد الدعم',
                    hintText: 'support@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),

                // Terms
                _SectionHeader(
                    icon: Icons.article_outlined,
                    title: 'الشروط والأحكام'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _termsController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'اكتب الشروط والأحكام هنا...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Privacy
                _SectionHeader(
                    icon: Icons.privacy_tip_outlined,
                    title: 'سياسة الخصوصية'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _privacyController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'اكتب سياسة الخصوصية هنا...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
