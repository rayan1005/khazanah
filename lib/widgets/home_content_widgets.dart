import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../models/banner_model.dart';
import '../models/home_section_model.dart';
import '../providers/home_content_provider.dart';
import '../providers/post_provider.dart';

/// Slider banners widget
class HomeBannerSlider extends ConsumerStatefulWidget {
  const HomeBannerSlider({super.key});

  @override
  ConsumerState<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends ConsumerState<HomeBannerSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(activeBannersStreamProvider);

    return bannersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        // Filter slider type banners
        final sliderBanners = banners.where((b) => b.type == BannerType.slider).toList();
        if (sliderBanners.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            // Slider
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: sliderBanners.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final banner = sliderBanners[index];
                  return _BannerCard(banner: banner);
                },
              ),
            ),

            // Dots indicator
            if (sliderBanners.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(sliderBanners.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : AppColors.textHint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerModel banner;

  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (banner.actionUrl != null && banner.actionUrl!.isNotEmpty) {
          // Handle navigation
          context.push(banner.actionUrl!);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: banner.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.shimmerBase,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.shimmerBase,
                child: const Icon(Icons.image, size: 48, color: AppColors.textHint),
              ),
            ),

            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      banner.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (banner.subtitle != null && banner.subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          banner.subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
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

/// Home section widget - displays different layouts
class HomeSection extends ConsumerWidget {
  final HomeSectionModel section;

  const HomeSection({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (section.showViewAll)
                  TextButton(
                    onPressed: () {
                      if (section.viewAllQuery != null) {
                        context.push(section.viewAllQuery!);
                      }
                    },
                    child: const Text('عرض الكل'),
                  ),
              ],
            ),
          ),
          if (section.subtitle != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                section.subtitle!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Items based on layout
          _buildLayout(context, ref),
        ],
      ),
    );
  }

  Widget _buildLayout(BuildContext context, WidgetRef ref) {
    switch (section.layout) {
      case SectionLayout.grid2:
        return _buildGrid(context, ref, 2);
      case SectionLayout.grid3:
        return _buildGrid(context, ref, 3);
      case SectionLayout.horizontal:
        return _buildHorizontal(context, ref);
      case SectionLayout.vertical:
        return _buildVertical(context, ref);
    }
  }

  Widget _buildGrid(BuildContext context, WidgetRef ref, int columns) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 2 ? 0.9 : 0.8,
        ),
        itemCount: section.items.length,
        itemBuilder: (context, index) {
          final item = section.items[index];
          return _SectionItemCard(
            item: item,
            onTap: () => _handleItemTap(context, ref, item),
          );
        },
      ),
    );
  }

  Widget _buildHorizontal(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: section.items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = section.items[index];
          return SizedBox(
            width: 130,
            child: _SectionItemCard(
              item: item,
              onTap: () => _handleItemTap(context, ref, item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVertical(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: section.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SectionItemTile(
              item: item,
              onTap: () => _handleItemTap(context, ref, item),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleItemTap(BuildContext context, WidgetRef ref, SectionItem item) {
    if (item.filterQuery.isNotEmpty) {
      // Parse filter query and apply filters
      final parts = item.filterQuery.replaceFirst('?', '').split('&');
      for (final part in parts) {
        final kv = part.split('=');
        if (kv.length == 2) {
          final key = kv[0];
          final value = Uri.decodeComponent(kv[1]);
          
          final currentFilters = ref.read(postFiltersProvider);
          switch (key) {
            case 'category':
              ref.read(postFiltersProvider.notifier).state = 
                  currentFilters.copyWith(category: value);
              break;
            case 'brand':
              ref.read(postFiltersProvider.notifier).state = 
                  currentFilters.copyWith(brand: value);
              break;
            case 'gender':
              ref.read(postFiltersProvider.notifier).state = 
                  currentFilters.copyWith(gender: value);
              break;
            case 'condition':
              ref.read(postFiltersProvider.notifier).state = 
                  currentFilters.copyWith(condition: value);
              break;
          }
        }
      }
    }
  }
}

class _SectionItemCard extends StatelessWidget {
  final SectionItem item;
  final VoidCallback onTap;

  const _SectionItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            item.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.shimmerBase),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.shimmerBase,
                      child: Center(
                        child: Text(
                          item.name.isNotEmpty ? item.name[0] : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.shimmerBase,
                    child: Center(
                      child: Text(
                        item.name.isNotEmpty ? item.name[0] : '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

            // Gradient overlay with name
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionItemTile extends StatelessWidget {
  final SectionItem item;
  final VoidCallback onTap;

  const _SectionItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            SizedBox(
              width: 100,
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      height: double.infinity,
                    )
                  : Container(
                      color: AppColors.shimmerBase,
                      child: Center(
                        child: Text(
                          item.name.isNotEmpty ? item.name[0] : '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تسوق الآن',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(Icons.arrow_back_ios, size: 16, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display all active home sections
class HomeSectionsView extends ConsumerWidget {
  const HomeSectionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(activeHomeSectionsStreamProvider);

    return sectionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sections) {
        if (sections.isEmpty) return const SizedBox.shrink();

        return Column(
          children: sections.map((section) {
            return HomeSection(section: section);
          }).toList(),
        );
      },
    );
  }
}
