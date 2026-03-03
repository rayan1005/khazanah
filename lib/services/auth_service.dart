import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/firestore_paths.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Send OTP via Cloud Function (Authentica API)
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final callable = _functions.httpsCallable('sendOTP');
      final result = await callable.call({'phone': phone});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      throw Exception('فشل إرسال رمز التحقق: $e');
    }
  }

  /// Verify OTP via Cloud Function (Authentica API)
  Future<String> verifyOtp(String phone, String code) async {
    try {
      final callable = _functions.httpsCallable('verifyOTP');
      final result = await callable.call({'phone': phone, 'otp': code});
      final data = Map<String, dynamic>.from(result.data);

      if (data['success'] == true) {
        final customToken = data['token'] as String;
        // Sign in with custom token
        await _auth.signInWithCustomToken(customToken);
        return data['uid'] as String;
      } else {
        throw Exception(data['message'] ?? 'رمز التحقق غير صحيح');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('فشل التحقق: $e');
    }
  }

  /// Check if user profile exists in Firestore
  Future<bool> hasProfile() async {
    if (uid == null) return false;
    final doc = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .get();
    return doc.exists && (doc.data()?['name'] ?? '').toString().isNotEmpty;
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    if (uid == null) return null;
    final doc = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  /// Create or update user profile
  Future<void> saveProfile(UserModel user) async {
    await _firestore
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete account
  Future<void> deleteAccount() async {
    if (uid == null) return;
    // Delete user document
    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .delete();
    // Delete Firebase Auth account
    await _auth.currentUser?.delete();
  }
}
