import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

/// Stream of notifications for a user
final notificationsStreamProvider = StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  return FirestoreService().notificationsStream(userId);
});

/// Stream of unread notifications count
final unreadNotificationsCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return FirestoreService().unreadNotificationsCountStream(userId);
});

/// Provider to check if a post is muted
final isPostMutedProvider = FutureProvider.family<bool, ({String userId, String postId})>((ref, params) {
  return FirestoreService().isPostMuted(params.userId, params.postId);
});

/// Muted state notifier for real-time updates
class PostMuteNotifier extends StateNotifier<bool> {
  final String userId;
  final String postId;
  final FirestoreService _service = FirestoreService();

  PostMuteNotifier({required this.userId, required this.postId}) : super(false) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    state = await _service.isPostMuted(userId, postId);
  }

  Future<void> toggle() async {
    state = await _service.togglePostMute(userId, postId);
  }
}

/// Provider family for post mute state
final postMuteNotifierProvider = StateNotifierProvider.family<PostMuteNotifier, bool, ({String userId, String postId})>(
  (ref, params) => PostMuteNotifier(userId: params.userId, postId: params.postId),
);
