import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/empty_state.dart';

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.login,
          title: 'سجّل دخولك لعرض إعلاناتك',
        ),
      );
    }

    final postsAsync = ref.watch(myPostsStreamProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myPosts),
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (posts) {
          if (posts.isEmpty) {
            return EmptyState(
              icon: Icons.post_add_rounded,
              title: 'لا توجد إعلانات',
              subtitle: 'أضف أول إعلان لك الآن',
              action: ElevatedButton.icon(
                onPressed: () => context.push('/add-post'),
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.addPost),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _MyPostCard(post: post);
            },
          );
        },
      ),
    );
  }
}

class _MyPostCard extends ConsumerWidget {
  final PostModel post;
  const _MyPostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/post/${post.postId}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: post.photos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: post.photos.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.shimmerBase,
                        child: const Icon(Icons.image),
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${post.price.toStringAsFixed(0)} ر.س',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _statusBadge(post),
                        const SizedBox(width: 8),
                        const Icon(Icons.visibility, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(
                          '${post.views}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions popup
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(context, ref, value),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text(AppStrings.editPost),
                      ],
                    ),
                  ),
                  if (post.isActive)
                    const PopupMenuItem(
                      value: 'sold',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 18, color: AppColors.success),
                          SizedBox(width: 8),
                          Text(AppStrings.markAsSold),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(AppStrings.deletePost,
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(PostModel post) {
    Color color;
    String text;
    switch (post.status) {
      case PostStatus.active:
        color = AppColors.success;
        text = AppStrings.active;
      case PostStatus.sold:
        color = AppColors.soldBadge;
        text = AppStrings.sold;
      case PostStatus.expired:
        color = AppColors.textHint;
        text = AppStrings.expired;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final service = ref.read(firestoreServiceProvider);
    switch (action) {
      case 'edit':
        context.push('/add-post', extra: post.postId);
      case 'sold':
        await service.markAsSold(post.postId);
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text(AppStrings.deletePost),
              content: const Text(AppStrings.confirmDelete),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text(AppStrings.deletePost),
                ),
              ],
            ),
          ),
        );
        if (confirm == true) {
          await service.deletePost(post.postId);
        }
    }
  }
}
