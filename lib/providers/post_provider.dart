import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';
import 'user_provider.dart';

// Selected city filter
final selectedCityProvider = StateProvider<String?>((ref) => null);

// Filter state
class PostFilters {
  final String? category;
  final String? brand;
  final String? size;
  final String? color;
  final String? condition;
  final String? gender;
  final double? minPrice;
  final double? maxPrice;

  const PostFilters({
    this.category,
    this.brand,
    this.size,
    this.color,
    this.condition,
    this.gender,
    this.minPrice,
    this.maxPrice,
  });

  PostFilters copyWith({
    String? category,
    String? brand,
    String? size,
    String? color,
    String? condition,
    String? gender,
    double? minPrice,
    double? maxPrice,
    bool clearCategory = false,
    bool clearBrand = false,
    bool clearSize = false,
    bool clearColor = false,
    bool clearCondition = false,
    bool clearGender = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return PostFilters(
      category: clearCategory ? null : (category ?? this.category),
      brand: clearBrand ? null : (brand ?? this.brand),
      size: clearSize ? null : (size ?? this.size),
      color: clearColor ? null : (color ?? this.color),
      condition: clearCondition ? null : (condition ?? this.condition),
      gender: clearGender ? null : (gender ?? this.gender),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
    );
  }

  bool get hasAnyFilter =>
      category != null ||
      brand != null ||
      size != null ||
      color != null ||
      condition != null ||
      gender != null ||
      minPrice != null ||
      maxPrice != null;
}

final postFiltersProvider = StateProvider<PostFilters>((ref) {
  return const PostFilters();
});

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Post list notifier with pagination
class PostListNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final FirestoreService _service;
  final String? city;
  final PostFilters filters;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  PostListNotifier(this._service, this.city, this.filters)
      : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> _loadInitial() async {
    try {
      final posts = await _service.getPosts(
        city: city,
        category: filters.category,
        brand: filters.brand,
        size: filters.size,
        color: filters.color,
        condition: filters.condition,
        gender: filters.gender,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        limit: 20,
      );
      _hasMore = posts.length >= 20;
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final currentPosts = state.valueOrNull ?? [];
    if (currentPosts.isEmpty) return;

    _isLoadingMore = true;

    try {
      // Get the last document snapshot for pagination
      final lastPostId = currentPosts.last.postId;
      final lastDocSnap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(lastPostId)
          .get();

      final newPosts = await _service.getPosts(
        city: city,
        category: filters.category,
        brand: filters.brand,
        size: filters.size,
        color: filters.color,
        condition: filters.condition,
        gender: filters.gender,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        lastDoc: lastDocSnap,
        limit: 20,
      );

      _hasMore = newPosts.length >= 20;
      state = AsyncValue.data([...currentPosts, ...newPosts]);
    } catch (e, st) {
      // Keep existing data on pagination error
      state = AsyncValue.data(currentPosts);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    _lastDoc = null;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _loadInitial();
  }
}

final postListProvider =
    StateNotifierProvider<PostListNotifier, AsyncValue<List<PostModel>>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  final city = ref.watch(selectedCityProvider);
  final filters = ref.watch(postFiltersProvider);
  return PostListNotifier(service, city, filters);
});

// Single post stream
final postDetailProvider = StreamProvider.family<PostModel?, String>((ref, postId) {
  final service = ref.read(firestoreServiceProvider);
  return service.postStream(postId);
});

// User's own posts stream
final myPostsStreamProvider = StreamProvider.family<List<PostModel>, String>((ref, userId) {
  final service = ref.read(firestoreServiceProvider);
  return service.userPostsStream(userId);
});

// Similar posts - accepts a record with category and excludeId
final similarPostsProvider = FutureProvider.family<List<PostModel>, ({String category, String excludeId})>((ref, params) async {
  final service = ref.read(firestoreServiceProvider);
  return service.getSimilarPostsByCategory(params.category, params.excludeId);
});
