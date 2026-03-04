import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/boutique_provider.dart';
import '../../models/user_model.dart';

class BoutiquesScreen extends ConsumerWidget {
  const BoutiquesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boutiquesAsync = ref.watch(boutiquesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.boutiques),
      ),
      body: boutiquesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (boutiques) {
          if (boutiques.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.noBoutiques,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: boutiques.length,
            itemBuilder: (context, index) {
              return _BoutiqueCard(boutique: boutiques[index]);
            },
          );
        },
      ),
    );
  }
}

class _BoutiqueCard extends StatelessWidget {
  final UserModel boutique;
  const _BoutiqueCard({required this.boutique});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/boutique/${boutique.uid}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  boutique.boutiqueCover != null
                      ? CachedNetworkImage(
                          imageUrl: boutique.boutiqueCover!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.shimmerBase,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: Icon(Icons.storefront,
                                color: AppColors.primary, size: 32),
                          ),
                        )
                      : Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.storefront,
                              color: AppColors.primary, size: 32),
                        ),
                  // Verified badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'معتمد',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Logo + Name
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: boutique.boutiqueLogo != null
                          ? CachedNetworkImageProvider(boutique.boutiqueLogo!)
                          : null,
                      child: boutique.boutiqueLogo == null
                          ? Icon(Icons.store,
                              size: 18, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            boutique.boutiqueName ?? boutique.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (boutique.city.isNotEmpty)
                            Text(
                              boutique.city,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
