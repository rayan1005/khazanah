import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import '../services/firestore_service.dart';

/// Provider for FirestoreService
final firestoreServiceProvider = Provider((ref) => FirestoreService());

/// Stream of comments for a specific post
final commentsStreamProvider = StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  return ref.watch(firestoreServiceProvider).commentsStream(postId);
});

/// Provider to add a comment
final addCommentProvider = Provider((ref) {
  return ({
    required String postId,
    required String userId,
    required String text,
    String? replyToCommentId,
    bool isPrivate = false,
  }) async {
    final service = ref.read(firestoreServiceProvider);
    return await service.addComment(
      postId: postId,
      userId: userId,
      text: text,
      replyToCommentId: replyToCommentId,
      isPrivate: isPrivate,
    );
  };
});

/// Provider for a single comment (for reply references)
final commentProvider = FutureProvider.family<CommentModel?, String>((ref, commentId) {
  return ref.watch(firestoreServiceProvider).getComment(commentId);
});
