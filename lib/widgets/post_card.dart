import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final bool isFavorited;
  final VoidCallback? onFavorite;

  const PostCard({
    super.key,
    required this.post,
    this.isFavorited = false,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/post/${post.postId}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  post.photos.isNotEmpty
                      ? Container(
                          color: AppColors.shimmerBase,
                          child: CachedNetworkImage(
                            imageUrl: post.photos.first,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.shimmerBase,
                              child: const Center(
                                child: Icon(Icons.image, color: AppColors.textHint),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.shimmerBase,
                              child: const Center(
                                child: Icon(Icons.broken_image, color: AppColors.textHint),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.shimmerBase,
                          child: const Center(
                            child: Icon(Icons.image, size: 40, color: AppColors.textHint),
                          ),
                        ),
                  // Sold badge
                  if (post.isSold)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: const Center(
                          child: RotationTransition(
                            turns: AlwaysStoppedAnimation(-15 / 360),
                            child: Text(
                              'تم البيع',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Condition badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _conditionColor(post.condition),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.condition,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 6,
                    left: 6,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorited ? AppColors.favorite : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Row(
                      children: [
                        Text(
                          '${post.price.toStringAsFixed(0)} ر.س',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        if (post.negotiable)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.negotiableBadge.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'قابل للتفاوض',
                              style: TextStyle(
                                fontSize: 8,
                                color: AppColors.negotiableBadge,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Brand + Size
                    Text(
                      '${post.brand} • ${post.size}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    // City
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(
                          post.city,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
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

  Color _conditionColor(String condition) {
    switch (condition) {
      case 'جديد بالتاق':
      case 'جديد':
        return AppColors.newBadge;
      case 'شبه جديد':
        return AppColors.info;
      case 'مستعمل نظيف':
        return AppColors.warning;
      case 'مستعمل':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}
