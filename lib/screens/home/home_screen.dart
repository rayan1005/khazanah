import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/saudi_cities.dart';
import '../../providers/post_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/skeletons/skeleton_loading.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/home_content_widgets.dart';
import 'filter_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(postListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postListProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    final filters = ref.watch(postFiltersProvider);
    final brandsAsync = ref.watch(visibleBrandsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final favoritesAsync = uid != null
        ? ref.watch(favoritesStreamProvider(uid))
        : null;
    final favoriteIds = favoritesAsync?.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          // Notifications bell
          if (uid != null)
            Consumer(builder: (context, ref, _) {
              final unreadCountAsync = ref.watch(unreadNotificationsCountProvider(uid));
              return IconButton(
                icon: Badge(
                  isLabelVisible: (unreadCountAsync.valueOrNull ?? 0) > 0,
                  label: Text(
                    '${unreadCountAsync.valueOrNull ?? 0}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => context.push('/notifications'),
              );
            }),
          // City selector
          TextButton.icon(
            onPressed: () => _showCityPicker(context),
            icon: const Icon(Icons.location_on, size: 18),
            label: Text(
              selectedCity ?? AppStrings.allCities,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.search,
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: IconButton(
                  icon: Badge(
                    isLabelVisible: filters.hasAnyFilter,
                    smallSize: 8,
                    child: const Icon(Icons.tune_rounded, size: 22),
                  ),
                  onPressed: () => _showFilters(context),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Banner slider
          const HomeBannerSlider(),
          const SizedBox(height: 8),

          // Brands horizontal scroll (circular avatars)
          brandsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (brands) => SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: brands.length,
                itemBuilder: (context, index) {
                  final brand = brands[index];
                  final isSelected = filters.brand == brand.name;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(postFiltersProvider.notifier).state =
                            isSelected
                                ? filters.copyWith(clearBrand: true)
                                : filters.copyWith(brand: brand.name);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.divider,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: brand.imageUrl != null && brand.imageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: brand.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: AppColors.primary.withValues(alpha: 0.05),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 16, height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 1.5),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => _brandFallback(brand.name),
                                    )
                                  : _brandFallback(brand.name),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            brand.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Filter chips (if any active)
          if (filters.hasAnyFilter)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (filters.category != null)
                    _filterChip(filters.category!, () {
                      ref.read(postFiltersProvider.notifier).state =
                          filters.copyWith(clearCategory: true);
                    }),
                  if (filters.brand != null)
                    _filterChip(filters.brand!, () {
                      ref.read(postFiltersProvider.notifier).state =
                          filters.copyWith(clearBrand: true);
                    }),
                  if (filters.condition != null)
                    _filterChip(filters.condition!, () {
                      ref.read(postFiltersProvider.notifier).state =
                          filters.copyWith(clearCondition: true);
                    }),
                  if (filters.gender != null)
                    _filterChip(filters.gender!, () {
                      ref.read(postFiltersProvider.notifier).state =
                          filters.copyWith(clearGender: true);
                    }),
                  if (filters.size != null)
                    _filterChip(filters.size!, () {
                      ref.read(postFiltersProvider.notifier).state =
                          filters.copyWith(clearSize: true);
                    }),
                  if (filters.color != null)
                    _filterChip(filters.color!, () {
                      ref.read(postFiltersProvider.notifier).state =
                          filters.copyWith(clearColor: true);
                    }),
                  // Reset all
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ActionChip(
                      label: const Text(AppStrings.resetFilters),
                      avatar: const Icon(Icons.clear_all, size: 16),
                      onPressed: () {
                        ref.read(postFiltersProvider.notifier).state =
                            const PostFilters();
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Post grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(postListProvider.notifier).refresh(),
              child: postsAsync.when(
                loading: () => const PostGridSkeleton(),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(AppStrings.somethingWentWrong),
                      TextButton(
                        onPressed: () =>
                            ref.read(postListProvider.notifier).refresh(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
                data: (posts) {
                  if (posts.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        EmptyState(
                          icon: Icons.shopping_bag_outlined,
                          title: AppStrings.noPostsFound,
                          subtitle: 'لا توجد إعلانات حالياً، جرّب تغيير المدينة أو الفلاتر',
                        ),
                      ],
                    );
                  }

                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: posts.length +
                        (ref.read(postListProvider.notifier).hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= posts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final post = posts[index];
                      return PostCard(
                        post: post,
                        isFavorited: favoriteIds.contains(post.postId),
                        onFavorite: uid != null
                            ? () => ref
                                .read(firestoreServiceProvider)
                                .toggleFavorite(uid, post.postId)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        side: BorderSide.none,
      ),
    );
  }

  void _showCityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.selectCity,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.public),
                        title: const Text(AppStrings.allCities),
                        selected: ref.read(selectedCityProvider) == null,
                        onTap: () {
                          ref.read(selectedCityProvider.notifier).state = null;
                          Navigator.pop(ctx);
                        },
                      ),
                      const Divider(),
                      ...SaudiCities.cities.map((city) => ListTile(
                            leading: const Icon(Icons.location_city),
                            title: Text(city),
                            selected: ref.read(selectedCityProvider) == city,
                            onTap: () {
                              ref.read(selectedCityProvider.notifier).state =
                                  city;
                              Navigator.pop(ctx);
                            },
                          )),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const FilterBottomSheet(),
    );
  }

  Widget _brandFallback(String name) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, name.length > 2 ? 2 : name.length) : '?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
