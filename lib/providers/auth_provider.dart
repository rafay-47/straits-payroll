import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firestore Service Provider
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

// Current Firebase User Stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current User Model Provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).streamUserProfile(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Auth Controller
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthController(this._authService, this._firestoreService)
      : super(const AsyncValue.data(null));

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithEmailPassword(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Create account
  Future<void> createAccount(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential =
          await _authService.createUserWithEmailPassword(email, password);
      if (credential?.user != null) {
        // Create user profile in Firestore
        final user = UserModel(
          uid: credential!.user!.uid,
          email: email,
          createdAt: DateTime.now(),
          isProfileComplete: false,
        );
        await _firestoreService.createUserProfile(user);
      }
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Update password
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    state = const AsyncValue.loading();
    try {
      await _authService.reauthenticateUser(currentPassword);
      await _authService.updatePassword(newPassword);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Auth Controller Provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authServiceProvider),
    ref.watch(firestoreServiceProvider),
  );
});
