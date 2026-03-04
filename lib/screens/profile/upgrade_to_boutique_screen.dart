import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/boutique_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/boutique_request_model.dart';

class UpgradeToBoutiqueScreen extends ConsumerStatefulWidget {
  const UpgradeToBoutiqueScreen({super.key});

  @override
  ConsumerState<UpgradeToBoutiqueScreen> createState() =>
      _UpgradeToBoutiqueScreenState();
}

class _UpgradeToBoutiqueScreenState
    extends ConsumerState<UpgradeToBoutiqueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _maaroofUrlController = TextEditingController();

  XFile? _certificateFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _maaroofUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _certificateFile = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_certificateFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحميل شهادة معروف')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final storage = StorageService();
      final firestore = FirestoreService();

      // Upload certificate
      final certUrl =
          await storage.uploadMaaroofCertificate(uid, _certificateFile!);

      // Submit request
      final request = BoutiqueRequestModel(
        id: '',
        userId: uid,
        boutiqueName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        instagramUrl: _instagramController.text.trim(),
        tiktokUrl: _tiktokController.text.trim().isEmpty
            ? null
            : _tiktokController.text.trim(),
        maaroofCertificateUrl: certUrl,
        maaroofUrl: _maaroofUrlController.text.trim().isEmpty
            ? ''
            : _maaroofUrlController.text.trim(),
        status: BoutiqueRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await firestore.submitBoutiqueRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلبك بنجاح وسيتم مراجعته'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final requestAsync = ref.watch(userBoutiqueRequestProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.boutiqueRequest),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (existingRequest) {
          // If user already has a request, show status
          if (existingRequest != null) {
            return _RequestStatusView(request: existingRequest);
          }

          // Show form
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.info, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'رقّي حسابك لبوتيك واحصلي على شارة التوثيق وصفحة متجر خاصة',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Boutique name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.boutiqueName,
                      prefixIcon: const Icon(Icons.store),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'يرجى إدخال اسم البوتيك'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: AppStrings.boutiqueDescription,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.description),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'يرجى إدخال وصف البوتيك'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Instagram (required)
                  TextFormField(
                    controller: _instagramController,
                    decoration: InputDecoration(
                      labelText: AppStrings.instagramAccount,
                      hintText: '@username',
                      prefixIcon: const Icon(Icons.camera_alt),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'يرجى إدخال حساب انستقرام'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // TikTok (optional)
                  TextFormField(
                    controller: _tiktokController,
                    decoration: InputDecoration(
                      labelText: AppStrings.tiktokAccount,
                      hintText: '@username',
                      prefixIcon: const Icon(Icons.music_note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ma'roof URL
                  TextFormField(
                    controller: _maaroofUrlController,
                    decoration: InputDecoration(
                      labelText: AppStrings.maaroofUrl,
                      hintText: 'https://maroof.sa/...',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Certificate upload
                  const Text(
                    'شهادة معروف *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickCertificate,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _certificateFile != null
                              ? AppColors.success
                              : AppColors.textHint,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _certificateFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_certificateFile!.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file,
                                    size: 40, color: AppColors.textHint),
                                const SizedBox(height: 8),
                                const Text(
                                  AppStrings.uploadMaaroofCertificate,
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              AppStrings.submitRequest,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestStatusView extends StatelessWidget {
  final BoutiqueRequestModel request;
  const _RequestStatusView({required this.request});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String message;

    switch (request.status) {
      case BoutiqueRequestStatus.pending:
        icon = Icons.hourglass_top;
        color = AppColors.warning;
        message = AppStrings.requestPending;
        break;
      case BoutiqueRequestStatus.approved:
        icon = Icons.check_circle;
        color = AppColors.success;
        message = AppStrings.requestApproved;
        break;
      case BoutiqueRequestStatus.rejected:
        icon = Icons.cancel;
        color = Colors.red;
        message = AppStrings.requestRejected;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: color),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اسم البوتيك: ${request.boutiqueName}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (request.status == BoutiqueRequestStatus.rejected &&
                request.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سبب الرفض: ${request.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
