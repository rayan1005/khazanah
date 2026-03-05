import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/boutique_provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class ManageBoutiquesScreen extends ConsumerWidget {
  const ManageBoutiquesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boutiquesAsync = ref.watch(allBoutiquesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.manageBoutiques),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: boutiquesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (boutiques) {
          if (boutiques.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد بوتيكات',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: boutiques.length,
            itemBuilder: (context, index) {
              return _BoutiqueAdminCard(boutique: boutiques[index]);
            },
          );
        },
      ),
    );
  }
}

class _BoutiqueAdminCard extends ConsumerStatefulWidget {
  final UserModel boutique;
  const _BoutiqueAdminCard({required this.boutique});

  @override
  ConsumerState<_BoutiqueAdminCard> createState() => _BoutiqueAdminCardState();
}

class _BoutiqueAdminCardState extends ConsumerState<_BoutiqueAdminCard> {
  bool _isLoading = false;

  Future<void> _toggleActive() async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = FirestoreService();
      if (widget.boutique.boutiqueActive) {
        await firestoreService.suspendBoutique(widget.boutique.uid);
      } else {
        await firestoreService.activateBoutique(widget.boutique.uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeBoutique() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سحب صلاحية البوتيك'),
        content: Text(
            'هل تريد سحب صلاحية البوتيك من "${widget.boutique.boutiqueName ?? widget.boutique.name}"؟ سيتحول الحساب لمستخدم عادي.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('سحب', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await FirestoreService().revokeBoutique(widget.boutique.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم سحب صلاحية البوتيك'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVisibility(String field, bool currentValue) async {
    try {
      await FirestoreService()
          .toggleBoutiqueVisibility(widget.boutique.uid, field, !currentValue);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.boutique;
    final isActive = b.boutiqueActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with logo & name
          ListTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: b.boutiqueLogo != null
                  ? CachedNetworkImageProvider(b.boutiqueLogo!)
                  : null,
              child: b.boutiqueLogo == null
                  ? Icon(Icons.store, size: 20, color: AppColors.primary)
                  : null,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    b.boutiqueName ?? b.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                if (!isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'موقوف',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              b.city.isNotEmpty ? b.city : 'غير محدد',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.storefront, size: 20),
              tooltip: 'عرض المتجر',
              onPressed: () => context.push('/boutique/${b.uid}'),
            ),
          ),

          const Divider(height: 1),

          // Visibility toggles
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إظهار الروابط للزوار',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _VisibilityChip(
                      label: 'انستقرام',
                      icon: Icons.camera_alt,
                      isVisible: b.showInstagram,
                      hasUrl: b.instagramUrl != null,
                      onToggle: () =>
                          _toggleVisibility('showInstagram', b.showInstagram),
                    ),
                    const SizedBox(width: 6),
                    _VisibilityChip(
                      label: 'تيكتوك',
                      icon: Icons.music_note,
                      isVisible: b.showTiktok,
                      hasUrl: b.tiktokUrl != null,
                      onToggle: () =>
                          _toggleVisibility('showTiktok', b.showTiktok),
                    ),
                    const SizedBox(width: 6),
                    _VisibilityChip(
                      label: 'معروف',
                      icon: Icons.verified_user,
                      isVisible: b.showMaaroof,
                      hasUrl: b.maaroofUrl != null,
                      onToggle: () =>
                          _toggleVisibility('showMaaroof', b.showMaaroof),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: _toggleActive,
                          icon: Icon(
                            isActive
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            size: 18,
                          ),
                          label: Text(
                            isActive
                                ? AppStrings.suspendBoutique
                                : AppStrings.activateBoutique,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isActive ? Colors.orange : AppColors.success,
                            side: BorderSide(
                              color: isActive
                                  ? Colors.orange
                                  : AppColors.success,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _revokeBoutique,
                  icon: const Icon(Icons.remove_circle, size: 18),
                  label: const Text('سحب', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isVisible;
  final bool hasUrl;
  final VoidCallback onToggle;

  const _VisibilityChip({
    required this.label,
    required this.icon,
    required this.isVisible,
    required this.hasUrl,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final active = isVisible && hasUrl;
    return GestureDetector(
      onTap: hasUrl ? onToggle : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.textHint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.textHint.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12,
                color: active ? AppColors.success : AppColors.textHint),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? AppColors.success : AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              active ? Icons.visibility : Icons.visibility_off,
              size: 12,
              color: active ? AppColors.success : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
