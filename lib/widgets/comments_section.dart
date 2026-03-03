import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../providers/comment_provider.dart';
import '../providers/user_provider.dart';
import '../providers/notification_provider.dart';
import '../services/firestore_service.dart';

class CommentsSection extends ConsumerStatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postTitle;
  final bool isPostSold;

  const CommentsSection({
    super.key,
    required this.postId,
    required this.postOwnerId,
    required this.postTitle,
    this.isPostSold = false,
  });

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isPrivate = false;
  String? _replyToCommentId;
  String? _replyToUserName;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setReplyTo(String commentId, String userName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserName = userName;
    });
  }

  void _clearReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserName = null;
    });
  }

  Future<void> _sendComment() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      context.push('/login');
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();

    // Get current user name
    final userAsync = ref.read(userStreamByIdProvider(uid));
    final userName = userAsync.valueOrNull?.name ?? 'مستخدم';

    // Add comment
    final comment = await FirestoreService().addComment(
      postId: widget.postId,
      userId: uid,
      text: text,
      replyToCommentId: _replyToCommentId,
      isPrivate: _isPrivate,
    );

    // Send notifications (unless commenting on own post and user muted)
    if (!_isPrivate) {
      await FirestoreService().notifyPostCommenters(
        postId: widget.postId,
        postTitle: widget.postTitle,
        commenterId: uid,
        commenterName: userName,
        commentText: text,
        commentId: comment.commentId,
      );
    }

    _clearReply();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final commentsAsync = ref.watch(commentsStreamProvider(widget.postId));
    final currentUserAsync = uid != null ? ref.watch(userStreamByIdProvider(uid)) : null;
    final isAdmin = currentUserAsync?.valueOrNull?.isAdmin ?? false;

    return Container(
      width: double.infinity,
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with mute button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: AppColors.surface,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.forum_outlined,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'التعليقات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (uid != null)
                  Consumer(builder: (context, ref, _) {
                    final muteNotifier = ref.watch(
                      postMuteNotifierProvider((userId: uid, postId: widget.postId)),
                    );
                    return Container(
                      decoration: BoxDecoration(
                        color: muteNotifier
                            ? AppColors.textHint.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          muteNotifier ? Icons.notifications_off : Icons.notifications_active,
                          size: 20,
                          color: muteNotifier ? AppColors.textHint : AppColors.primary,
                        ),
                        tooltip: muteNotifier ? 'تفعيل الإشعارات' : 'إيقاف الإشعارات',
                        onPressed: () {
                          ref
                              .read(postMuteNotifierProvider((userId: uid, postId: widget.postId)).notifier)
                              .toggle();
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),

        // Comments list with min height 400
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 400),
          child: commentsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('خطأ: $e'),
            ),
            data: (comments) {
              // Filter comments based on visibility
              final visibleComments = comments.where((c) {
                if (!c.isPrivate) return true;
                // Private comments visible to: owner, admin, or comment author
                if (uid == null) return false;
                return uid == widget.postOwnerId || isAdmin || uid == c.userId;
              }).toList();

              if (visibleComments.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'لا توجد تعليقات بعد.\nكن أول من يعلّق!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: visibleComments.length,
                itemBuilder: (context, index) {
                  final comment = visibleComments[index];
                  return _CommentBubble(
                    comment: comment,
                    isPostOwner: comment.userId == widget.postOwnerId,
                    currentUserId: uid,
                    postOwnerId: widget.postOwnerId,
                    isAdmin: isAdmin,
                    onReply: () {
                      final userAsync = ref.read(userStreamByIdProvider(comment.userId));
                      _setReplyTo(comment.commentId, userAsync.valueOrNull?.name ?? 'مستخدم');
                    },
                    replyToComment: comment.replyToCommentId != null
                        ? comments.cast<CommentModel?>().firstWhere(
                              (c) => c?.commentId == comment.replyToCommentId,
                              orElse: () => null,
                            )
                        : null,
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Input bar (disabled if sold)
        if (!widget.isPostSold)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reply indicator
                  if (_replyToCommentId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.reply, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'رد على $_replyToUserName',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _clearReply,
                            child: const Icon(Icons.close, size: 16, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      // Private toggle
                      GestureDetector(
                        onTap: () => setState(() => _isPrivate = !_isPrivate),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isPrivate
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isPrivate ? Icons.lock : Icons.lock_open,
                            size: 20,
                            color: _isPrivate ? AppColors.primary : AppColors.textHint,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: _isPrivate
                                ? 'تعليق خاص (مرئي للبائع فقط)...'
                                : 'أضف تعليقاً...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send, color: AppColors.primary),
                        onPressed: _sendComment,
                      ),
                    ],
                  ),
                  if (_isPrivate)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '🔒 هذا التعليق سيظهر لصاحب الإعلان فقط',
                        style: TextStyle(fontSize: 10, color: AppColors.textHint),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CommentBubble extends ConsumerWidget {
  final CommentModel comment;
  final bool isPostOwner;
  final String? currentUserId;
  final String postOwnerId;
  final bool isAdmin;
  final VoidCallback onReply;
  final CommentModel? replyToComment;

  const _CommentBubble({
    required this.comment,
    required this.isPostOwner,
    required this.currentUserId,
    required this.postOwnerId,
    required this.isAdmin,
    required this.onReply,
    this.replyToComment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamByIdProvider(comment.userId));
    final replyUserAsync = replyToComment != null
        ? ref.watch(userStreamByIdProvider(replyToComment!.userId))
        : null;

    // Post owner comments on left, others on right
    final isOwnerComment = comment.userId == postOwnerId;
    final alignment = isOwnerComment ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final bubbleColor = isOwnerComment
        ? AppColors.primary.withValues(alpha: 0.1)
        : AppColors.background;
    final textColor = isOwnerComment ? AppColors.primary : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // Reply reference
          if (replyToComment != null)
            Container(
              margin: EdgeInsets.only(
                right: isOwnerComment ? 0 : 40,
                left: isOwnerComment ? 40 : 0,
                bottom: 4,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.reply, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    replyUserAsync?.valueOrNull?.name ?? '...',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      replyToComment!.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isOwnerComment ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              // Avatar (only for others)
              if (!isOwnerComment) ...[
                const SizedBox(width: 32), // Space for reply button
              ],
              if (isOwnerComment)
                userAsync.when(
                  data: (user) => _buildAvatar(user),
                  loading: () => _buildAvatarPlaceholder(),
                  error: (_, __) => _buildAvatarPlaceholder(),
                ),
              if (isOwnerComment) const SizedBox(width: 8),

              // Bubble
              Flexible(
                child: GestureDetector(
                  onLongPress: onReply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(16),
                      border: comment.isPrivate
                          ? Border.all(color: AppColors.warning, width: 1)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username & time
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            userAsync.when(
                              data: (user) => Text(
                                user?.name ?? 'مستخدم',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              loading: () => const Text('...'),
                              error: (_, __) => const Text('مستخدم'),
                            ),
                            if (isPostOwner)
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'البائع',
                                  style: TextStyle(fontSize: 8, color: Colors.white),
                                ),
                              ),
                            if (comment.isPrivate)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.lock, size: 12, color: AppColors.warning),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Comment text
                        Text(
                          comment.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Time
                        Text(
                          _formatTime(comment.createdAt),
                          style: const TextStyle(fontSize: 9, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (!isOwnerComment) const SizedBox(width: 8),
              if (!isOwnerComment)
                userAsync.when(
                  data: (user) => _buildAvatar(user),
                  loading: () => _buildAvatarPlaceholder(),
                  error: (_, __) => _buildAvatarPlaceholder(),
                ),

              // Reply button
              if (isOwnerComment) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.reply, size: 16, color: AppColors.textHint),
                  onPressed: onReply,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserModel? user) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundImage: user?.photoUrl != null
          ? CachedNetworkImageProvider(user!.photoUrl!)
          : null,
      child: user?.photoUrl == null
          ? Text(
              user?.name.isNotEmpty == true ? user!.name[0] : '?',
              style: TextStyle(
                  fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
            )
          : null,
    );
  }

  Widget _buildAvatarPlaceholder() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.shimmerBase,
      child: const Icon(Icons.person, size: 16, color: AppColors.textHint),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
