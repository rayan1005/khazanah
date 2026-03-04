import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/boutique_request_model.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import 'user_provider.dart';

/// Stream of all boutique users
final boutiquesStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.boutiquesStream();
});

/// Stream of user's boutique request
final userBoutiqueRequestProvider =
    StreamProvider.family<BoutiqueRequestModel?, String>((ref, userId) {
  final service = ref.read(firestoreServiceProvider);
  return service.userBoutiqueRequestStream(userId);
});

/// Stream of pending boutique requests (admin)
final pendingBoutiqueRequestsProvider =
    StreamProvider<List<BoutiqueRequestModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.pendingBoutiqueRequestsStream();
});

/// Stream of all boutique requests (admin)
final allBoutiqueRequestsProvider =
    StreamProvider<List<BoutiqueRequestModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.allBoutiqueRequestsStream();
});

/// Boutique active posts
final boutiquePostsProvider =
    FutureProvider.family<List<PostModel>, String>((ref, userId) async {
  final service = ref.read(firestoreServiceProvider);
  return service.getBoutiqueActivePosts(userId);
});
