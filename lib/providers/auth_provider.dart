import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Auth service singleton
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firebase auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Current user profile stream (real-time updates)
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromDoc(doc) : null);
});

// Auth state notifier for OTP flow
class AuthNotifier extends StateNotifier<AuthFlowState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthFlowState());

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.sendOtp(phone);
      state = state.copyWith(isLoading: false, phone: phone);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final uid = await _authService.verifyOtp(state.phone, code);
      state = state.copyWith(isLoading: false, uid: uid);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> hasProfile() async {
    return await _authService.hasProfile();
  }

  void reset() {
    state = const AuthFlowState();
  }
}

class AuthFlowState {
  final bool isLoading;
  final String phone;
  final String? uid;
  final String? error;

  const AuthFlowState({
    this.isLoading = false,
    this.phone = '',
    this.uid,
    this.error,
  });

  AuthFlowState copyWith({
    bool? isLoading,
    String? phone,
    String? uid,
    String? error,
  }) {
    return AuthFlowState(
      isLoading: isLoading ?? this.isLoading,
      phone: phone ?? this.phone,
      uid: uid ?? this.uid,
      error: error,
    );
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthFlowState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
