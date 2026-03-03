import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 80, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 120, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 60, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostGridSkeleton extends StatelessWidget {
  final int count;
  const PostGridSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const PostCardSkeleton(),
    );
  }
}

class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white),
        title: Container(height: 14, width: 100, color: Colors.white),
        subtitle: Container(height: 12, width: 160, color: Colors.white),
        trailing: Container(height: 10, width: 40, color: Colors.white),
      ),
    );
  }
}
