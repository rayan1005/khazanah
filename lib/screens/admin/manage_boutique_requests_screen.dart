import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/boutique_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/boutique_request_model.dart';

class ManageBoutiqueRequestsScreen extends ConsumerWidget {
  const ManageBoutiqueRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(allBoutiqueRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.manageBoutiqueRequests),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد طلبات',
                style: TextStyle(color: AppColors.textHint, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _RequestCard(request: requests[index]);
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final BoutiqueRequestModel request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamByIdProvider(request.userId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            userAsync.when(
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox.shrink(),
              data: (user) {
                if (user == null) return const SizedBox.shrink();
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: user.photoUrl != null
                          ? CachedNetworkImageProvider(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(user.name.isNotEmpty ? user.name[0] : '?',
                              style: TextStyle(color: AppColors.primary))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(user.phone,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    _StatusBadge(status: request.status.name),
                  ],
                );
              },
            ),
            const Divider(height: 20),

            // Request details
            _DetailRow(
                label: 'اسم البوتيك', value: request.boutiqueName),
            _DetailRow(label: 'الوصف', value: request.description),
            _DetailRow(
                label: 'انستقرام', value: request.instagramUrl),
            if (request.tiktokUrl != null)
              _DetailRow(label: 'تيكتوك', value: request.tiktokUrl!),
            if (request.maaroofUrl.isNotEmpty)
              _DetailRow(
                  label: 'رابط معروف', value: request.maaroofUrl),

            // Certificate image
            const SizedBox(height: 8),
            const Text('شهادة معروف:',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showCertificateDialog(
                  context, request.maaroofCertificateUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: request.maaroofCertificateUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 120,
                    color: AppColors.shimmerBase,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 120,
                    color: AppColors.shimmerBase,
                    child: const Center(
                      child:
                          Icon(Icons.broken_image, color: AppColors.textHint),
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons
            if (request.status == BoutiqueRequestStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approve(context),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('قبول'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('رفض'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (request.status == BoutiqueRequestStatus.rejected &&
                request.rejectionReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'سبب الرفض: ${request.rejectionReason}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCertificateDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد القبول'),
        content: Text(
            'هل تريد قبول طلب "${request.boutiqueName}" وترقية الحساب لبوتيك؟'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('قبول',
                style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirestoreService().approveBoutiqueRequest(request);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم قبول الطلب وترقية الحساب'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
          );
        }
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تريد رفض طلب "${request.boutiqueName}"؟'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child:
                const Text('رفض', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirestoreService().rejectBoutiqueRequest(
          request.id,
          reasonController.text.trim().isEmpty
              ? ''
              : reasonController.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض الطلب')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
          );
        }
      }
    }
    reasonController.dispose();
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = 'قيد المراجعة';
        break;
      case 'approved':
        color = AppColors.success;
        text = 'مقبول';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'مرفوض';
        break;
      default:
        color = AppColors.textHint;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
