import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/empty_state.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول')),
      );
    }

    final favoritesAsync = ref.watch(favoritePostsProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.favorites),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (posts) {
          if (posts.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: AppStrings.noFavorites,
              subtitle: 'أضف إعلانات إلى المفضلة لتظهر هنا',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                isFavorited: true,
                onFavorite: () async {
                  await ref
                      .read(firestoreServiceProvider)
                      .toggleFavorite(uid, post.postId);
                },
              );
            },
          );
        },
      ),
    );
  }
}
