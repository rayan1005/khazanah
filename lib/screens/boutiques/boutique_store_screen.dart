import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/boutique_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/post_card.dart';

class BoutiqueStoreScreen extends ConsumerWidget {
  final String userId;
  const BoutiqueStoreScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamByIdProvider(userId));
    final postsAsync = ref.watch(boutiquePostsProvider(userId));
    final currentUser = ref.watch(currentUserStreamProvider).valueOrNull;
    final isOwner = currentUser?.uid == userId;
    final isAdmin = currentUser?.role == 'admin';

    return Scaffold(
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('لم يتم العثور على البوتيك'));
          }

          return CustomScrollView(
            slivers: [
              // Cover + Logo header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: IconButton(
                  icon: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 16, color: Colors.black),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  if (isOwner)
                    IconButton(
                      icon: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, size: 16, color: Colors.black),
                      ),
                      onPressed: () => context.push('/edit-boutique'),
                    ),
                  if (isOwner)
                    IconButton(
                      icon: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(
                          user.boutiqueActive
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          size: 16,
                          color: user.boutiqueActive
                              ? Colors.orange
                              : AppColors.success,
                        ),
                      ),
                      onPressed: () =>
                          _toggleSelfSuspend(context, ref, user),
                    ),
                  if (!isOwner)
                    PopupMenuButton<String>(
                      icon: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.more_vert,
                            size: 16, color: Colors.black),
                      ),
                      onSelected: (value) {
                        if (value == 'report') {
                          _showReportDialog(context, ref, user.uid);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag, size: 18, color: AppColors.error),
                              SizedBox(width: 8),
                              Text(AppStrings.reportBoutique),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover
                      user.boutiqueCover != null
                          ? CachedNetworkImage(
                              imageUrl: user.boutiqueCover!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                            )
                          : Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Suspended banner
              if (!user.boutiqueActive)
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.error.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            AppStrings.boutiqueSuspended,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Boutique info section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Logo + Name + Verified
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: user.boutiqueLogo != null
                                ? CachedNetworkImageProvider(
                                    user.boutiqueLogo!)
                                : null,
                            child: user.boutiqueLogo == null
                                ? Icon(Icons.store,
                                    size: 28, color: AppColors.primary)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.boutiqueName ?? user.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.verified,
                                        size: 20, color: AppColors.info),
                                  ],
                                ),
                                if (user.city.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 14,
                                            color: AppColors.textHint),
                                        const SizedBox(width: 2),
                                        Text(
                                          user.city,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Description
                      if (user.boutiqueDescription != null &&
                          user.boutiqueDescription!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            user.boutiqueDescription!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      // Social links (respect visibility flags)
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (user.instagramUrl != null &&
                              (user.showInstagram || isOwner || isAdmin))
                            _SocialButton(
                              icon: Icons.camera_alt,
                              label: 'انستقرام',
                              color: const Color(0xFFE1306C),
                              onTap: () => _launchUrl(user.instagramUrl!),
                            ),
                          if (user.tiktokUrl != null &&
                              (user.showTiktok || isOwner || isAdmin))
                            _SocialButton(
                              icon: Icons.music_note,
                              label: 'تيكتوك',
                              color: Colors.black87,
                              onTap: () => _launchUrl(user.tiktokUrl!),
                            ),
                          if (user.snapchatUrl != null &&
                              (user.showSnapchat || isOwner || isAdmin))
                            _SocialButton(
                              icon: Icons.snapchat,
                              label: 'سناب شات',
                              color: const Color(0xFFE4A81D),
                              onTap: () => _launchUrl(user.snapchatUrl!),
                            ),
                          if ((user.maaroofCertificateUrl != null ||
                                  user.maaroofUrl != null) &&
                              (user.showMaaroof || isOwner || isAdmin))
                            _SocialButton(
                              icon: Icons.verified_user,
                              label: 'معروف',
                              color: const Color(0xFF2E7D32),
                              onTap: () {
                                if (user.maaroofCertificateUrl != null &&
                                    user.maaroofCertificateUrl!.isNotEmpty) {
                                  _showCertificateDialog(
                                      context, user.maaroofCertificateUrl!);
                                } else if (user.maaroofUrl != null) {
                                  _launchUrl(user.maaroofUrl!);
                                }
                              },
                            ),
                        ],
                      ),
                      const Divider(height: 32),
                      // Posts header
                      const Row(
                        children: [
                          Icon(Icons.grid_view, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'المنتجات',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Posts grid
              postsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text('$e')),
                ),
                data: (posts) {
                  if (posts.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          AppStrings.noPostsFound,
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.65,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return PostCard(post: posts[index]);
                        },
                        childCount: posts.length,
                      ),
                    ),
                  );
                },
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleSelfSuspend(
      BuildContext context, WidgetRef ref, dynamic user) async {
    final willSuspend = user.boutiqueActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(willSuspend ? 'إيقاف البوتيك' : 'تفعيل البوتيك'),
        content: Text(willSuspend
            ? 'هل تريد إيقاف البوتيك مؤقتاً؟ لن يظهر متجرك للمستخدمين.'
            : 'هل تريد إعادة تفعيل البوتيك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              willSuspend ? 'إيقاف' : 'تفعيل',
              style: TextStyle(
                  color: willSuspend ? Colors.orange : AppColors.success),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final firestoreService = FirestoreService();
      if (willSuspend) {
        await firestoreService.suspendBoutique(user.uid);
      } else {
        await firestoreService.activateBoutique(user.uid);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(willSuspend ? 'تم إيقاف البوتيك مؤقتاً' : 'تم تفعيل البوتيك'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context, WidgetRef ref, String boutiqueUserId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.reportBoutique),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'اكتب سبب البلاغ...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              final currentUser =
                  ref.read(currentUserStreamProvider).valueOrNull;
              if (currentUser == null) return;

              await FirestoreService().reportBoutique(
                boutiqueUserId: boutiqueUserId,
                reporterId: currentUser.uid,
                reason: reason,
              );

              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.boutiqueReportSubmitted),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('إرسال',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    String finalUrl = url;
    if (!url.startsWith('http')) {
      finalUrl = 'https://$url';
    }
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCertificateDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.verified_user,
                      color: Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'شهادة معروف',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Center(child: Icon(Icons.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
