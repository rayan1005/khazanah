import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Get any user by ID
final userByIdProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  final service = ref.read(firestoreServiceProvider);
  return await service.getUser(uid);
});

// Stream any user by ID
final userStreamByIdProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  final service = ref.read(firestoreServiceProvider);
  return service.userStream(uid);
});

// All users stream (admin)
final allUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.allUsersStream();
});
