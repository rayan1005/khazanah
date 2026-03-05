import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/report_model.dart';
import '../models/favorite_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/banner_model.dart';
import '../models/home_section_model.dart';
import '../models/quick_filter_model.dart';
import '../models/boutique_request_model.dart';
import '../models/app_settings_model.dart';
import '../core/constants/firestore_paths.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== POSTS ====================

  /// Get posts stream filtered by city, with pagination
  Query<Map<String, dynamic>> postsQuery({
    String? city,
    String? category,
    String? brand,
    String? size,
    String? color,
    String? condition,
    String? gender,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(FirestorePaths.posts)
        .where('status', isEqualTo: PostStatus.active.name);

    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (brand != null && brand.isNotEmpty) {
      query = query.where('brand', isEqualTo: brand);
    }
    if (size != null && size.isNotEmpty) {
      query = query.where('size', isEqualTo: size);
    }
    if (color != null && color.isNotEmpty) {
      query = query.where('color', isEqualTo: color);
    }
    if (condition != null && condition.isNotEmpty) {
      query = query.where('condition', isEqualTo: condition);
    }
    if (gender != null && gender.isNotEmpty) {
      query = query.where('gender', isEqualTo: gender);
    }
    if (minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }

    query = query.orderBy('createdAt', descending: true);
    return query;
  }

  /// Get paginated posts
  Future<List<PostModel>> getPosts({
    String? city,
    String? category,
    String? brand,
    String? size,
    String? color,
    String? condition,
    String? gender,
    double? minPrice,
    double? maxPrice,
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = postsQuery(
      city: city,
      category: category,
      brand: brand,
      size: size,
      color: color,
      condition: condition,
      gender: gender,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => PostModel.fromDoc(doc)).toList();
  }

  /// Get single post
  Future<PostModel?> getPost(String postId) async {
    final doc = await _db.collection(FirestorePaths.posts).doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromDoc(doc);
  }

  /// Get post stream
  Stream<PostModel?> postStream(String postId) {
    return _db
        .collection(FirestorePaths.posts)
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists ? PostModel.fromDoc(doc) : null);
  }

  /// Create post
  Future<String> createPost(PostModel post) async {
    final docRef = _db.collection(FirestorePaths.posts).doc();
    final newPost = post.copyWith(postId: docRef.id);
    await docRef.set(newPost.toMap());
    return docRef.id;
  }

  /// Update post
  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    await _db.collection(FirestorePaths.posts).doc(postId).update(data);
  }

  /// Delete post
  Future<void> deletePost(String postId) async {
    await _db.collection(FirestorePaths.posts).doc(postId).delete();
  }

  /// Mark post as sold
  Future<void> markAsSold(String postId) async {
    await _db
        .collection(FirestorePaths.posts)
        .doc(postId)
        .update({'status': PostStatus.sold.name});
  }

  /// Increment views
  Future<void> incrementViews(String postId) async {
    await _db
        .collection(FirestorePaths.posts)
        .doc(postId)
        .update({'views': FieldValue.increment(1)});
  }

  /// Get user's posts
  Stream<List<PostModel>> userPostsStream(String userId) {
    return _db
        .collection(FirestorePaths.posts)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostModel.fromDoc(d)).toList());
  }

  /// Get similar posts (same category or brand)
  Future<List<PostModel>> getSimilarPosts(PostModel post, {int limit = 6}) async {
    final snapshot = await _db
        .collection(FirestorePaths.posts)
        .where('status', isEqualTo: PostStatus.active.name)
        .where('category', isEqualTo: post.category)
        .where('postId', isNotEqualTo: post.postId)
        .limit(limit)
        .get();
    return snapshot.docs.map((d) => PostModel.fromDoc(d)).toList();
  }

  /// Get similar posts by category string, excluding a post ID
  Future<List<PostModel>> getSimilarPostsByCategory(String category, String excludeId, {int limit = 6}) async {
    final snapshot = await _db
        .collection(FirestorePaths.posts)
        .where('status', isEqualTo: PostStatus.active.name)
        .where('category', isEqualTo: category)
        .limit(limit + 1)
        .get();
    return snapshot.docs
        .map((d) => PostModel.fromDoc(d))
        .where((p) => p.postId != excludeId)
        .take(limit)
        .toList();
  }

  // ==================== USERS ====================

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  /// User profile stream
  Stream<UserModel?> userStream(String uid) {
    return _db
        .collection(FirestorePaths.users)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromDoc(doc) : null);
  }

  /// Get all users (admin)
  Stream<List<UserModel>> allUsersStream() {
    return _db
        .collection(FirestorePaths.users)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromDoc(d)).toList());
  }

  /// Ban/unban user
  Future<void> toggleBan(String uid, bool ban) async {
    await _db.collection(FirestorePaths.users).doc(uid).update({'isBanned': ban});
  }

  // ==================== CATEGORIES ====================

  Stream<List<CategoryModel>> categoriesStream() {
    return _db
        .collection(FirestorePaths.categories)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map((d) => CategoryModel.fromDoc(d)).toList());
  }

  Future<void> addCategory(CategoryModel category) async {
    await _db.collection(FirestorePaths.categories).add(category.toMap());
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _db.collection(FirestorePaths.categories).doc(id).update(data);
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection(FirestorePaths.categories).doc(id).delete();
  }

  // ==================== BRANDS ====================

  Stream<List<BrandModel>> brandsStream() {
    return _db
        .collection(FirestorePaths.brands)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map((d) => BrandModel.fromDoc(d)).toList());
  }

  /// Get brands that have posts in a specific city
  Future<List<String>> brandsInCity(String city) async {
    final snapshot = await _db
        .collection(FirestorePaths.posts)
        .where('status', isEqualTo: PostStatus.active.name)
        .where('city', isEqualTo: city)
        .get();
    final brands = snapshot.docs
        .map((d) => d.data()['brand'] as String?)
        .where((b) => b != null && b.isNotEmpty)
        .toSet()
        .toList();
    return brands.cast<String>();
  }

  Future<void> addBrand(BrandModel brand) async {
    await _db.collection(FirestorePaths.brands).add(brand.toMap());
  }

  Future<void> updateBrand(String id, Map<String, dynamic> data) async {
    await _db.collection(FirestorePaths.brands).doc(id).update(data);
  }

  Future<void> deleteBrand(String id) async {
    await _db.collection(FirestorePaths.brands).doc(id).delete();
  }

  // ==================== FAVORITES ====================

  /// Toggle favorite
  Future<bool> toggleFavorite(String userId, String postId) async {
    final query = await _db
        .collection(FirestorePaths.favorites)
        .where('userId', isEqualTo: userId)
        .where('postId', isEqualTo: postId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
      return false;
    } else {
      final fav = FavoriteModel(
        id: '',
        userId: userId,
        postId: postId,
        createdAt: DateTime.now(),
      );
      await _db.collection(FirestorePaths.favorites).add(fav.toMap());
      return true;
    }
  }

  /// Check if post is favorited
  Future<bool> isFavorited(String userId, String postId) async {
    final query = await _db
        .collection(FirestorePaths.favorites)
        .where('userId', isEqualTo: userId)
        .where('postId', isEqualTo: postId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Get user's favorite post IDs stream
  Stream<List<String>> favoritesStream(String userId) {
    return _db
        .collection(FirestorePaths.favorites)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => d.data()['postId'] as String).toList());
  }

  /// Get user's favorite posts
  Future<List<PostModel>> getFavoritePosts(String userId) async {
    final favSnap = await _db
        .collection(FirestorePaths.favorites)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    final postIds = favSnap.docs.map((d) => d.data()['postId'] as String).toList();
    if (postIds.isEmpty) return [];

    // Fetch in batches of 10 (Firestore whereIn limit)
    final posts = <PostModel>[];
    for (var i = 0; i < postIds.length; i += 10) {
      final batch = postIds.sublist(i, i + 10 > postIds.length ? postIds.length : i + 10);
      final snap = await _db
          .collection(FirestorePaths.posts)
          .where('postId', whereIn: batch)
          .get();
      posts.addAll(snap.docs.map((d) => PostModel.fromDoc(d)));
    }
    return posts;
  }

  // ==================== REPORTS ====================

  Future<void> reportPost(ReportModel report) async {
    await _db.collection(FirestorePaths.reports).add(report.toMap());
  }

  Stream<List<ReportModel>> reportsStream() {
    return _db
        .collection(FirestorePaths.reports)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ReportModel.fromDoc(d)).toList());
  }

  Future<void> deleteReport(String id) async {
    await _db.collection(FirestorePaths.reports).doc(id).delete();
  }

  // ==================== STATS (Admin) ====================

  Future<Map<String, int>> getDashboardStats() async {
    final posts = await _db.collection(FirestorePaths.posts).count().get();
    final users = await _db.collection(FirestorePaths.users).count().get();

    final activeCitiesSnap = await _db
        .collection(FirestorePaths.posts)
        .where('status', isEqualTo: PostStatus.active.name)
        .get();
    final cities = activeCitiesSnap.docs
        .map((d) => d.data()['city'] as String?)
        .where((c) => c != null)
        .toSet();

    return {
      'totalPosts': posts.count ?? 0,
      'totalUsers': users.count ?? 0,
      'activeCities': cities.length,
    };
  }

  /// Alias for admin panel stats
  Future<Map<String, int>> getAdminStats() async {
    final posts = await _db.collection(FirestorePaths.posts).count().get();
    final users = await _db.collection(FirestorePaths.users).count().get();
    final reports = await _db.collection(FirestorePaths.reports).count().get();
    return {
      'posts': posts.count ?? 0,
      'users': users.count ?? 0,
      'reports': reports.count ?? 0,
    };
  }

  /// Get user's posts as a one-time future
  Future<List<PostModel>> getUserPosts(String userId) async {
    final snap = await _db
        .collection(FirestorePaths.posts)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: PostStatus.active.name)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => PostModel.fromDoc(d)).toList();
  }

  /// Create a report with named params
  Future<void> createReport({
    required String postId,
    required String reporterId,
    required String reason,
  }) async {
    await _db.collection(FirestorePaths.reports).add({
      'postId': postId,
      'reporterId': reporterId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Create category with named params
  Future<void> createCategory({required String name, required String icon, String sizeType = 'clothes'}) async {
    final count = (await _db.collection(FirestorePaths.categories).count().get()).count ?? 0;
    await _db.collection(FirestorePaths.categories).add({
      'name': name,
      'icon': icon,
      'sizeType': sizeType,
      'order': count,
    });
  }

  /// Create brand with named params
  Future<void> createBrand({required String name, String? imageUrl}) async {
    final count = (await _db.collection(FirestorePaths.brands).count().get()).count ?? 0;
    await _db.collection(FirestorePaths.brands).add({
      'name': name,
      'imageUrl': imageUrl,
      'order': count,
    });
  }

  /// Create brand with specific ID
  Future<void> createBrandWithId({required String id, required String name, String? imageUrl}) async {
    final count = (await _db.collection(FirestorePaths.brands).count().get()).count ?? 0;
    await _db.collection(FirestorePaths.brands).doc(id).set({
      'name': name,
      'imageUrl': imageUrl,
      'order': count,
    });
  }

  /// Update user document
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection(FirestorePaths.users).doc(uid).update(data);
  }

  // ==================== COMMENTS ====================

  /// Get comments stream for a post
  Stream<List<CommentModel>> commentsStream(String postId) {
    return _db
        .collection(FirestorePaths.comments)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommentModel.fromDoc(d)).toList());
  }

  /// Add a comment
  Future<CommentModel> addComment({
    required String postId,
    required String userId,
    required String text,
    String? replyToCommentId,
    bool isPrivate = false,
  }) async {
    final comment = CommentModel(
      commentId: '',
      postId: postId,
      userId: userId,
      text: text,
      createdAt: DateTime.now(),
      replyToCommentId: replyToCommentId,
      isPrivate: isPrivate,
    );
    final docRef = await _db.collection(FirestorePaths.comments).add(comment.toMap());
    return comment.copyWith(commentId: docRef.id);
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    await _db.collection(FirestorePaths.comments).doc(commentId).delete();
  }

  /// Get a specific comment
  Future<CommentModel?> getComment(String commentId) async {
    final doc = await _db.collection(FirestorePaths.comments).doc(commentId).get();
    if (!doc.exists) return null;
    return CommentModel.fromDoc(doc);
  }

  /// Get all user IDs who commented on a post (for notifications)
  Future<List<String>> getPostCommenters(String postId) async {
    final snap = await _db
        .collection(FirestorePaths.comments)
        .where('postId', isEqualTo: postId)
        .get();
    final userIds = snap.docs.map((d) => d.data()['userId'] as String).toSet();
    return userIds.toList();
  }

  // ==================== NOTIFICATIONS ====================

  /// Get notifications stream for a user
  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _db
        .collection(FirestorePaths.notifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => NotificationModel.fromDoc(d)).toList());
  }

  /// Get unread notifications count stream
  Stream<int> unreadNotificationsCountStream(String userId) {
    return _db
        .collection(FirestorePaths.notifications)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Create a notification
  Future<void> createNotification({
    required String userId,
    required String postId,
    String? commentId,
    required NotificationType type,
    required String title,
    required String message,
    String? triggeredByUserId,
  }) async {
    final notification = NotificationModel(
      notificationId: '',
      userId: userId,
      postId: postId,
      commentId: commentId,
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      triggeredByUserId: triggeredByUserId,
    );
    await _db.collection(FirestorePaths.notifications).add(notification.toMap());
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    await _db.collection(FirestorePaths.notifications).doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _db
        .collection(FirestorePaths.notifications)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _db.collection(FirestorePaths.notifications).doc(notificationId).delete();
  }

  // ==================== POST MUTES ====================

  /// Check if user has muted a post
  Future<bool> isPostMuted(String userId, String postId) async {
    final snap = await _db
        .collection(FirestorePaths.postMutes)
        .where('userId', isEqualTo: userId)
        .where('postId', isEqualTo: postId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Toggle mute for a post
  Future<bool> togglePostMute(String userId, String postId) async {
    final snap = await _db
        .collection(FirestorePaths.postMutes)
        .where('userId', isEqualTo: userId)
        .where('postId', isEqualTo: postId)
        .limit(1)
        .get();
    
    if (snap.docs.isNotEmpty) {
      // Unmute
      await snap.docs.first.reference.delete();
      return false;
    } else {
      // Mute
      await _db.collection(FirestorePaths.postMutes).add({
        'userId': userId,
        'postId': postId,
        'mutedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }
  }

  /// Get muted post IDs for a user
  Future<List<String>> getMutedPostIds(String userId) async {
    final snap = await _db
        .collection(FirestorePaths.postMutes)
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs.map((d) => d.data()['postId'] as String).toList();
  }

  /// Send notifications to all commenters on a post (except the commenter)
  Future<void> notifyPostCommenters({
    required String postId,
    required String postTitle,
    required String commenterId,
    required String commenterName,
    required String commentText,
    String? commentId,
  }) async {
    // Get post owner
    final postDoc = await _db.collection(FirestorePaths.posts).doc(postId).get();
    if (!postDoc.exists) return;
    final postOwnerId = postDoc.data()?['userId'] as String?;
    
    // Get all commenters
    final commenters = await getPostCommenters(postId);
    
    // Get muted users
    final allTargets = <String>{};
    if (postOwnerId != null) allTargets.add(postOwnerId);
    allTargets.addAll(commenters);
    allTargets.remove(commenterId); // Don't notify the commenter
    
    // Filter out muted users
    for (final targetUserId in allTargets) {
      final isMuted = await isPostMuted(targetUserId, postId);
      if (!isMuted) {
        final isOwner = targetUserId == postOwnerId;
        await createNotification(
          userId: targetUserId,
          postId: postId,
          commentId: commentId,
          type: NotificationType.newComment,
          title: isOwner ? 'تعليق جديد على إعلانك' : 'رد جديد',
          message: '$commenterName: ${commentText.length > 50 ? '${commentText.substring(0, 50)}...' : commentText}',
          triggeredByUserId: commenterId,
        );
      }
    }
  }

  // ==================== BANNERS ====================

  /// Get all banners stream
  Stream<List<BannerModel>> bannersStream() {
    return _db
        .collection(FirestorePaths.banners)
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BannerModel.fromDoc(doc)).toList());
  }

  /// Get active banners only
  Stream<List<BannerModel>> activeBannersStream() {
    return _db
        .collection(FirestorePaths.banners)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BannerModel.fromDoc(doc))
            .where((b) => b.isValid)
            .toList());
  }

  /// Create banner
  Future<String> createBanner(BannerModel banner) async {
    final docRef = await _db.collection(FirestorePaths.banners).add(banner.toMap());
    return docRef.id;
  }

  /// Create banner with specific ID
  Future<void> createBannerWithId(String id, BannerModel banner) async {
    await _db.collection(FirestorePaths.banners).doc(id).set(banner.toMap());
  }

  /// Update banner
  Future<void> updateBanner(String id, Map<String, dynamic> data) async {
    await _db.collection(FirestorePaths.banners).doc(id).update(data);
  }

  /// Delete banner
  Future<void> deleteBanner(String id) async {
    await _db.collection(FirestorePaths.banners).doc(id).delete();
  }

  /// Reorder banners
  Future<void> reorderBanners(List<String> orderedIds) async {
    final batch = _db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        _db.collection(FirestorePaths.banners).doc(orderedIds[i]),
        {'order': i},
      );
    }
    await batch.commit();
  }

  // ==================== HOME SECTIONS ====================

  /// Get all home sections stream
  Stream<List<HomeSectionModel>> homeSectionsStream() {
    return _db
        .collection(FirestorePaths.homeSections)
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => HomeSectionModel.fromDoc(doc)).toList());
  }

  /// Get active home sections only
  Stream<List<HomeSectionModel>> activeHomeSectionsStream() {
    return _db
        .collection(FirestorePaths.homeSections)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => HomeSectionModel.fromDoc(doc)).toList());
  }

  /// Create home section
  Future<String> createHomeSection(HomeSectionModel section) async {
    final docRef = await _db.collection(FirestorePaths.homeSections).add(section.toMap());
    return docRef.id;
  }

  /// Create home section with specific ID
  Future<void> createHomeSectionWithId(String id, HomeSectionModel section) async {
    await _db.collection(FirestorePaths.homeSections).doc(id).set(section.toMap());
  }

  /// Update home section
  Future<void> updateHomeSection(String id, Map<String, dynamic> data) async {
    await _db.collection(FirestorePaths.homeSections).doc(id).update(data);
  }

  /// Delete home section
  Future<void> deleteHomeSection(String id) async {
    await _db.collection(FirestorePaths.homeSections).doc(id).delete();
  }

  /// Reorder home sections
  Future<void> reorderHomeSections(List<String> orderedIds) async {
    final batch = _db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        _db.collection(FirestorePaths.homeSections).doc(orderedIds[i]),
        {'order': i},
      );
    }
    await batch.commit();
  }

  // ==================== QUICK FILTERS ====================

  /// Get all quick filters stream
  Stream<List<QuickFilterModel>> quickFiltersStream() {
    return _db
        .collection(FirestorePaths.quickFilters)
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QuickFilterModel.fromDoc(doc)).toList());
  }

  /// Get active quick filters only
  Stream<List<QuickFilterModel>> activeQuickFiltersStream() {
    return _db
        .collection(FirestorePaths.quickFilters)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QuickFilterModel.fromDoc(doc)).toList());
  }

  /// Create quick filter
  Future<String> createQuickFilter(QuickFilterModel filter) async {
    final docRef = await _db.collection(FirestorePaths.quickFilters).add(filter.toMap());
    return docRef.id;
  }

  /// Update quick filter
  Future<void> updateQuickFilter(String id, Map<String, dynamic> data) async {
    await _db.collection(FirestorePaths.quickFilters).doc(id).update(data);
  }

  /// Delete quick filter
  Future<void> deleteQuickFilter(String id) async {
    await _db.collection(FirestorePaths.quickFilters).doc(id).delete();
  }

  /// Reorder quick filters
  Future<void> reorderQuickFilters(List<String> orderedIds) async {
    final batch = _db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        _db.collection(FirestorePaths.quickFilters).doc(orderedIds[i]),
        {'order': i},
      );
    }
    await batch.commit();
  }

  // ==================== BOUTIQUE REQUESTS ====================

  /// Submit a boutique upgrade request
  Future<String> submitBoutiqueRequest(BoutiqueRequestModel request) async {
    final docRef = await _db
        .collection(FirestorePaths.boutiqueRequests)
        .add(request.toMap());
    return docRef.id;
  }

  /// Get user's boutique request
  Stream<BoutiqueRequestModel?> userBoutiqueRequestStream(String userId) {
    return _db
        .collection(FirestorePaths.boutiqueRequests)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty
            ? BoutiqueRequestModel.fromDoc(snap.docs.first)
            : null);
  }

  /// Get all pending boutique requests (admin)
  Stream<List<BoutiqueRequestModel>> pendingBoutiqueRequestsStream() {
    return _db
        .collection(FirestorePaths.boutiqueRequests)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BoutiqueRequestModel.fromDoc(d)).toList());
  }

  /// Get all boutique requests (admin)
  Stream<List<BoutiqueRequestModel>> allBoutiqueRequestsStream() {
    return _db
        .collection(FirestorePaths.boutiqueRequests)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BoutiqueRequestModel.fromDoc(d)).toList());
  }

  /// Approve boutique request
  Future<void> approveBoutiqueRequest(BoutiqueRequestModel request) async {
    final batch = _db.batch();

    // Update request status
    batch.update(
      _db.collection(FirestorePaths.boutiqueRequests).doc(request.id),
      {
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
      },
    );

    // Update user to boutique
    batch.update(
      _db.collection(FirestorePaths.users).doc(request.userId),
      {
        'accountType': 'boutique',
        'boutiqueActive': true,
        'boutiqueName': request.boutiqueName,
        'boutiqueDescription': request.description,
        'instagramUrl': request.instagramUrl,
        'tiktokUrl': request.tiktokUrl,
        'snapchatUrl': request.snapchatUrl,
        'maaroofUrl': request.maaroofUrl,
        'maaroofCertificateUrl': request.maaroofCertificateUrl,
      },
    );

    await batch.commit();
  }

  /// Reject boutique request
  Future<void> rejectBoutiqueRequest(String requestId, String reason) async {
    await _db
        .collection(FirestorePaths.boutiqueRequests)
        .doc(requestId)
        .update({
      'status': 'rejected',
      'rejectionReason': reason,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all boutique users (for boutiques tab - only active)
  /// Filters client-side to handle legacy docs without boutiqueActive field
  Stream<List<UserModel>> boutiquesStream() {
    return _db
        .collection(FirestorePaths.users)
        .where('accountType', isEqualTo: 'boutique')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserModel.fromDoc(d))
            .where((u) => u.boutiqueActive)
            .toList());
  }

  /// Get all boutique users including suspended (admin)
  Stream<List<UserModel>> allBoutiquesStream() {
    return _db
        .collection(FirestorePaths.users)
        .where('accountType', isEqualTo: 'boutique')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromDoc(d)).toList());
  }

  /// Get posts by a specific user (for boutique store page)
  Future<List<PostModel>> getBoutiqueActivePosts(String userId, {int limit = 50}) async {
    final snap = await _db
        .collection(FirestorePaths.posts)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: PostStatus.active.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => PostModel.fromDoc(d)).toList();
  }

  /// Update boutique profile (for owner edit)
  Future<void> updateBoutiqueProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection(FirestorePaths.users).doc(uid).update(data);
  }

  /// Suspend boutique (admin)
  Future<void> suspendBoutique(String uid) async {
    await _db.collection(FirestorePaths.users).doc(uid).update({
      'boutiqueActive': false,
    });
  }

  /// Activate boutique (admin)
  Future<void> activateBoutique(String uid) async {
    await _db.collection(FirestorePaths.users).doc(uid).update({
      'boutiqueActive': true,
    });
  }

  /// Revoke boutique status (admin - downgrade to user)
  Future<void> revokeBoutique(String uid) async {
    await _db.collection(FirestorePaths.users).doc(uid).update({
      'accountType': 'user',
      'boutiqueActive': false,
    });
  }

  /// Toggle boutique link visibility (admin)
  Future<void> toggleBoutiqueVisibility(String uid, String field, bool value) async {
    await _db.collection(FirestorePaths.users).doc(uid).update({
      field: value,
    });
  }

  /// Toggle link visibility for ALL boutiques at once (admin)
  Future<void> toggleAllBoutiquesVisibility(String field, bool value) async {
    final snap = await _db
        .collection(FirestorePaths.users)
        .where('accountType', isEqualTo: 'boutique')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {field: value});
    }
    await batch.commit();
  }

  /// Report a boutique
  Future<void> reportBoutique({
    required String boutiqueUserId,
    required String reporterId,
    required String reason,
  }) async {
    await _db.collection('boutiqueReports').add({
      'boutiqueUserId': boutiqueUserId,
      'reporterId': reporterId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get boutique reports stream (admin)
  Stream<List<Map<String, dynamic>>> boutiqueReportsStream() {
    return _db
        .collection('boutiqueReports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  /// Delete boutique report
  Future<void> deleteBoutiqueReport(String id) async {
    await _db.collection('boutiqueReports').doc(id).delete();
  }

  /// Delete boutique completely (admin) - reverts to user and removes boutique data
  Future<void> deleteBoutique(String uid) async {
    await _db.collection(FirestorePaths.users).doc(uid).update({
      'accountType': 'user',
      'boutiqueActive': false,
      'boutiqueName': FieldValue.delete(),
      'boutiqueDescription': FieldValue.delete(),
      'boutiqueLogo': FieldValue.delete(),
      'boutiqueCover': FieldValue.delete(),
      'instagramUrl': FieldValue.delete(),
      'tiktokUrl': FieldValue.delete(),
      'snapchatUrl': FieldValue.delete(),
      'maaroofUrl': FieldValue.delete(),
      'maaroofCertificateUrl': FieldValue.delete(),
      'showInstagram': FieldValue.delete(),
      'showTiktok': FieldValue.delete(),
      'showSnapchat': FieldValue.delete(),
      'showMaaroof': FieldValue.delete(),
    });
  }

  // ==================== APP SETTINGS ====================

  /// Get app settings stream
  Stream<AppSettingsModel> appSettingsStream() {
    return _db
        .collection('appSettings')
        .doc('config')
        .snapshots()
        .map((doc) => AppSettingsModel.fromDoc(doc));
  }

  /// Get app settings once
  Future<AppSettingsModel> getAppSettings() async {
    final doc = await _db.collection('appSettings').doc('config').get();
    return AppSettingsModel.fromDoc(doc);
  }

  /// Update app settings
  Future<void> updateAppSettings(Map<String, dynamic> data) async {
    await _db.collection('appSettings').doc('config').set(
      data,
      SetOptions(merge: true),
    );
  }
}
