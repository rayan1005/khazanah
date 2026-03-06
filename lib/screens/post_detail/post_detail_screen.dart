import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/chat_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/comments_section.dart';
import '../../providers/app_settings_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  int _currentPhoto = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Increment views
    FirestoreService().incrementViews(widget.postId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openWhatsApp(String phone, String postTitle) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      context.push('/login');
      return;
    }
    final msg = Uri.encodeComponent('مرحباً، أنا مهتم بإعلانك: $postTitle');
    final url = 'https://wa.me/${phone.replaceAll('+', '')}?text=$msg';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _startChat(String sellerId, String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      context.push('/login');
      return;
    }
    // if (uid == sellerId) return; // Disabled for testing

    final chatId =
        await ChatService().getOrCreateChat(uid, sellerId, postId);
    if (mounted) {
      context.push('/chat/$chatId');
    }
  }

  void _showFullScreenImage(BuildContext context, List<String> photos, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenImageViewer(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _reportPost() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? selected;
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text(AppStrings.report),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...[
                  'محتوى غير لائق',
                  'إعلان مزيف / احتيال',
                  'سعر غير واقعي',
                  'منتج مقلّد',
                  'سبب آخر',
                ].map((r) => RadioListTile<String>(
                      value: r,
                      groupValue: selected,
                      title: Text(r),
                      onChanged: (v) =>
                          setDialogState(() => selected = v),
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => ctx.pop(),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: selected != null ? () => ctx.pop(selected) : null,
                child: const Text(AppStrings.send),
              ),
            ],
          );
        });
      },
    );

    if (reason != null && mounted) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        context.push('/login');
        return;
      }
      await FirestoreService().createReport(
        postId: widget.postId,
        reporterId: uid,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال البلاغ، شكراً لك')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return postAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('$e')),
      ),
      data: (post) {
        if (post == null) {
          return const Scaffold(
            body: EmptyState(
              icon: Icons.error_outline,
              title: 'الإعلان غير موجود',
            ),
          );
        }

        final sellerAsync = ref.watch(userStreamByIdProvider(post.userId));
        final isMine = uid == post.userId;

        // Favorites
        final favsAsync =
            uid != null ? ref.watch(favoritesStreamProvider(uid)) : null;
        final isFavorite = favsAsync?.when(
              data: (favs) => favs.contains(widget.postId),
              loading: () => false,
              error: (_, __) => false,
            ) ??
            false;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Photo carousel
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                leading: IconButton(
                  icon: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 16, color: Colors.black),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.share,
                          size: 16, color: Colors.black),
                    ),
                    onPressed: () {
                      share_plus.Share.share('شاهد إعلان "${post.title}" على خزانة!');
                    },
                  ),
                  if (!isMine)
                    IconButton(
                      icon: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.flag_outlined,
                            size: 16, color: Colors.black),
                      ),
                      onPressed: _reportPost,
                    ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: post.photos.isNotEmpty
                      ? Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: post.photos.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentPhoto = i),
                              itemBuilder: (_, i) => GestureDetector(
                                onTap: () => _showFullScreenImage(context, post.photos, i),
                                child: Container(
                                  color: Colors.white,
                                  child: CachedNetworkImage(
                                    imageUrl: post.photos[i],
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                            if (post.photos.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: List.generate(
                                    post.photos.length,
                                    (i) => Container(
                                      width: i == _currentPhoto ? 20 : 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: i == _currentPhoto
                                            ? Colors.white
                                            : Colors.white54,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // Sold overlay
                            if (post.status == PostStatus.sold)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: Text(
                                    AppStrings.sold,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          color: AppColors.background,
                          child: const Icon(Icons.image,
                              size: 64, color: AppColors.textHint),
                        ),
                ),
              ),

              // Details
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title, Description & Price card - full width with bottom rounded corners
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Description (if exists, smaller)
                            if (post.description != null && post.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                post.description!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Price row
                            Row(
                              children: [
                                Text(
                                  '${post.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'ر.س',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                                if (post.purchasePrice != null) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'سعر الشراء: ${post.purchasePrice!.toStringAsFixed(0)} ر.س',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                                if (post.negotiable) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      AppStrings.negotiable,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (!isMine)
                                  GestureDetector(
                                    onTap: () async {
                                      if (uid == null) {
                                        context.push('/login');
                                        return;
                                      }
                                      await FirestoreService()
                                          .toggleFavorite(uid, widget.postId);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? AppColors.favorite
                                            : Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quick info row (compact)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _QuickInfoItemCompact(
                              icon: Icons.visibility_outlined,
                              value: '${post.views}',
                            ),
                            Container(width: 1, height: 20, color: AppColors.divider),
                            _QuickInfoItemCompact(
                              icon: Icons.calendar_today_outlined,
                              value: '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                            ),
                            Container(width: 1, height: 20, color: AppColors.divider),
                            _QuickInfoItemCompact(
                              icon: Icons.location_on_outlined,
                              value: post.city,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Product details section
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.info_outline,
                                      color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'تفاصيل المنتج',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _DetailRow(
                              icon: Icons.category_outlined,
                              label: 'الفئة',
                              value: post.category,
                            ),
                            if (post.brand != null)
                              _DetailRow(
                                icon: Icons.shopping_bag_outlined,
                                label: 'الماركة',
                                value: post.brand!,
                              ),
                            _DetailRow(
                              icon: Icons.grade_outlined,
                              label: 'الحالة',
                              value: post.condition,
                              valueColor: _getConditionColor(post.condition),
                            ),
                            if (post.size != null)
                              _DetailRow(
                                icon: Icons.straighten_outlined,
                                label: 'المقاس',
                                value: post.size!,
                              ),
                            if (post.color != null)
                              _DetailRow(
                                icon: Icons.palette_outlined,
                                label: 'اللون',
                                value: post.color!,
                              ),
                            _DetailRow(
                              icon: Icons.person_outline,
                              label: 'النوع',
                              value: post.gender,
                              isLast: post.purchasePrice == null,
                            ),
                            if (post.purchasePrice != null)
                              _DetailRow(
                                icon: Icons.receipt_long_outlined,
                                label: 'سعر الشراء',
                                value: '${post.purchasePrice!.toStringAsFixed(0)} ر.س',
                                isLast: true,
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Seller card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: sellerAsync.when(
                          loading: () => const Center(
                              child: CircularProgressIndicator()),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (seller) {
                            if (seller == null) return const SizedBox.shrink();
                            return _SellerCard(
                              seller: seller,
                              onTap: () => context.push('/user/${seller.uid}'),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Comments section - full width
              if (post.commentsEnabled)
                SliverToBoxAdapter(
                  child: CommentsSection(
                    postId: post.postId,
                    postOwnerId: post.userId,
                    postTitle: post.title,
                    isPostSold: post.status == PostStatus.sold,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.comments_disabled_outlined,
                            size: 18, color: AppColors.textHint),
                        SizedBox(width: 8),
                        Text(
                          'التعليقات معطلة لهذا الإعلان',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Similar posts with styled header
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: AppColors.warning, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        AppStrings.similarPosts,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _SimilarPostsSection(
                category: post.category,
                excludeId: post.postId,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),

          // Bottom action bar (visible for testing even on own posts)
          bottomNavigationBar: post.status == PostStatus.sold
              ? null
              : Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mediator warning
                        Consumer(
                          builder: (context, ref, _) {
                            final settingsAsync =
                                ref.watch(appSettingsStreamProvider);
                            return settingsAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (settings) {
                                if (settings.mediatorWarningText.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          size: 14,
                                          color: AppColors.textHint),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          settings.mediatorWarningText,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        _buildContactButton(post, sellerAsync),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildContactButton(PostModel post, AsyncValue<dynamic> sellerAsync) {
    final bothEnabled = post.allowChat && post.allowWhatsapp;
    final chatOnly = post.allowChat && !post.allowWhatsapp;
    final whatsappOnly = !post.allowChat && post.allowWhatsapp;

    if (bothEnabled) {
      // Show both buttons side by side
      return sellerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (seller) {
          final whatsappNumber = post.customWhatsapp ?? seller?.phone;
          return Row(
            children: [
              // Chat button
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _startChat(post.userId, post.postId),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'محادثة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // WhatsApp button
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: (whatsappNumber != null && whatsappNumber.isNotEmpty)
                        ? AppColors.whatsapp
                        : AppColors.textHint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: (whatsappNumber != null && whatsappNumber.isNotEmpty)
                          ? () => _openWhatsApp(whatsappNumber, post.title)
                          : null,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'واتساب',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else if (chatOnly) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _startChat(post.userId, post.postId),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  AppStrings.chatWithSeller,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // WhatsApp only
      return sellerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('خطأ في تحميل بيانات البائع'),
        data: (seller) {
          final whatsappNumber = post.customWhatsapp ?? seller?.phone;
          if (whatsappNumber == null || whatsappNumber.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'البائع لم يضف رقم هاتف',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }
          return Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.whatsapp,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.whatsapp.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openWhatsApp(whatsappNumber, post.title),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.chat,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      AppStrings.openWhatsApp,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'جديد':
        return AppColors.success;
      case 'جديد بالتاغ':
        return AppColors.success;
      case 'ممتاز':
        return AppColors.primary;
      case 'جيد جداً':
        return AppColors.info;
      case 'جيد':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}

// Quick info item widget
class _QuickInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _QuickInfoItem({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (sublabel.isNotEmpty)
            Text(
              sublabel,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
        ],
      ),
    );
  }
}

// Compact quick info item (50% smaller)
class _QuickInfoItemCompact extends StatelessWidget {
  final IconData icon;
  final String value;

  const _QuickInfoItemCompact({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textHint, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// Detail row for product info
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textHint),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (valueColor ?? AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

// Seller card widget
class _SellerCard extends StatelessWidget {
  final UserModel seller;
  final VoidCallback onTap;

  const _SellerCard({
    required this.seller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.primaryLight.withValues(alpha: 0.1),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: seller.photoUrl != null
                    ? CachedNetworkImageProvider(seller.photoUrl!)
                    : null,
                child: seller.photoUrl == null
                    ? Text(
                        seller.name.isNotEmpty ? seller.name[0] : '?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'البائع',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    seller.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (seller.city != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          seller.city!,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimilarPostsSection extends ConsumerWidget {
  final String category;
  final String excludeId;

  const _SimilarPostsSection(
      {required this.category, required this.excludeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarAsync =
        ref.watch(similarPostsProvider((category: category, excludeId: excludeId)));

    return similarAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (posts) {
        if (posts.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: posts.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(left: 10),
                child: SizedBox(
                  width: 160,
                  child: PostCard(
                    post: posts[i],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen zoomable image viewer
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Zoomable images
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.photos[i],
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Page indicator
          if (widget.photos.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photos.length,
                  (i) => Container(
                    width: i == _current ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _current ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

          // Counter
          if (widget.photos.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_current + 1} / ${widget.photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
