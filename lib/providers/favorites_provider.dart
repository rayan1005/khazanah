import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import 'user_provider.dart';

// Favorite post IDs stream for current user
final favoritesStreamProvider = StreamProvider.family<List<String>, String>((ref, userId) {
  final service = ref.read(firestoreServiceProvider);
  return service.favoritesStream(userId);
});

// Favorite posts list
final favoritePostsProvider = FutureProvider.family<List<PostModel>, String>((ref, userId) async {
  final service = ref.read(firestoreServiceProvider);
  return service.getFavoritePosts(userId);
});
