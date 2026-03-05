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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Global visibility toggles
              _GlobalVisibilitySection(boutiques: boutiques),
              const SizedBox(height: 16),
              // Boutique list
              ...boutiques.map((b) => _BoutiqueAdminCard(boutique: b)),
            ],
          );
        },
      ),
    );
  }
}

/// Global toggles to show/hide social links for ALL boutiques
class _GlobalVisibilitySection extends StatefulWidget {
  final List<UserModel> boutiques;
  const _GlobalVisibilitySection({required this.boutiques});

  @override
  State<_GlobalVisibilitySection> createState() =>
      _GlobalVisibilitySectionState();
}

class _GlobalVisibilitySectionState extends State<_GlobalVisibilitySection> {
  bool _isLoading = false;

  /// Check if majority of boutiques have this field enabled
  bool _majorityEnabled(String field) {
    int enabled = 0;
    for (final b in widget.boutiques) {
      final val = field == 'showInstagram'
          ? b.showInstagram
          : field == 'showTiktok'
              ? b.showTiktok
              : field == 'showSnapchat'
                  ? b.showSnapchat
                  : b.showMaaroof;
      if (val) enabled++;
    }
    return enabled > widget.boutiques.length / 2;
  }

  Future<void> _toggleAll(String field, bool newValue) async {
    setState(() => _isLoading = true);
    try {
      await FirestoreService().toggleAllBoutiquesVisibility(field, newValue);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newValue
                ? 'تم إظهار الرابط لجميع البوتيكات'
                : 'تم إخفاء الرابط لجميع البوتيكات'),
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

  @override
  Widget build(BuildContext context) {
    final instagramOn = _majorityEnabled('showInstagram');
    final tiktokOn = _majorityEnabled('showTiktok');
    final snapchatOn = _majorityEnabled('showSnapchat');
    final maaroofOn = _majorityEnabled('showMaaroof');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  'التحكم بالروابط لجميع البوتيكات',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'إظهار أو إخفاء الروابط الاجتماعية لكل البوتيكات دفعة واحدة',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _GlobalToggleButton(
                      label: 'انستقرام',
                      icon: Icons.camera_alt,
                      isEnabled: instagramOn,
                      onToggle: () =>
                          _toggleAll('showInstagram', !instagramOn),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GlobalToggleButton(
                      label: 'تيكتوك',
                      icon: Icons.music_note,
                      isEnabled: tiktokOn,
                      onToggle: () =>
                          _toggleAll('showTiktok', !tiktokOn),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GlobalToggleButton(
                      label: 'سناب',
                      icon: Icons.photo_camera_front,
                      isEnabled: snapchatOn,
                      onToggle: () =>
                          _toggleAll('showSnapchat', !snapchatOn),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GlobalToggleButton(
                      label: 'معروف',
                      icon: Icons.verified_user,
                      isEnabled: maaroofOn,
                      onToggle: () =>
                          _toggleAll('showMaaroof', !maaroofOn),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _GlobalToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onToggle;

  const _GlobalToggleButton({
    required this.label,
    required this.icon,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.textHint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.textHint.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20,
                color: isEnabled ? AppColors.success : AppColors.textHint),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isEnabled ? AppColors.success : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              isEnabled ? Icons.visibility : Icons.visibility_off,
              size: 14,
              color: isEnabled ? AppColors.success : AppColors.textHint,
            ),
          ],
        ),
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

  Future<void> _deleteBoutique() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف البوتيك نهائياً'),
        content: Text(
            'هل تريد حذف البوتيك "${widget.boutique.boutiqueName ?? widget.boutique.name}" نهائياً؟ سيتم تحويل الحساب لمستخدم عادي وحذف جميع بيانات البوتيك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف نهائياً',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await FirestoreService().deleteBoutique(widget.boutique.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف البوتيك نهائياً'),
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
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _deleteBoutique,
                  icon: const Icon(Icons.delete_forever,
                      color: AppColors.error, size: 22),
                  tooltip: 'حذف نهائياً',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
