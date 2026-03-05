import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/user_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/empty_state.dart';
import '../../services/firestore_service.dart';
import '../../models/post_model.dart';

/// Provider for fetching a specific user's active posts
final userPostsProvider =
    FutureProvider.family<List<PostModel>, String>((ref, userId) async {
  final service = ref.read(firestoreServiceProvider);
  return service.getUserPosts(userId);
});

class OtherUserProfileScreen extends ConsumerWidget {
  final String userId;
  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamByIdProvider(userId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('الملف الشخصي'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('المستخدم غير موجود'));
          }

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: user.photoUrl != null
                            ? CachedNetworkImageProvider(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.name.isNotEmpty ? user.name[0] : '?',
                                style: TextStyle(
                                    fontSize: 28,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      if (user.city != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(user.city!,
                                style: const TextStyle(
                                    color: AppColors.textHint)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // WhatsApp button
                      if (user.whatsapp != null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.chat,
                                color: AppColors.whatsapp),
                            label: const Text(AppStrings.openWhatsApp),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.whatsapp,
                              side: const BorderSide(
                                  color: AppColors.whatsapp),
                            ),
                            onPressed: () async {
                              final url =
                                  'https://wa.me/${user.whatsapp!.replaceAll('+', '')}';
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url),
                                    mode:
                                        LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Divider
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'إعلانات هذا المستخدم',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // User's posts
              _UserPostsGrid(userId: userId),
            ],
          );
        },
      ),
    );
  }
}

class _UserPostsGrid extends ConsumerWidget {
  final String userId;
  const _UserPostsGrid({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(userId));

    return postsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(child: Text('$e')),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const SliverFillRemaining(
            child: EmptyState(
              icon: Icons.grid_off,
              title: 'لا توجد إعلانات',
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => PostCard(
                post: posts[i],
              ),
              childCount: posts.length,
            ),
          ),
        );
      },
    );
  }
}
