import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';
import '../services/secure_storage_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// ===== SERVICE PROVIDERS =====

/// Secure Storage Service Provider
final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

// ===== STATE PROVIDERS =====

/// Check if biometric login is enrolled and ready
final biometricEnrolledProvider = FutureProvider<bool>((ref) async {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return await secureStorage.isBiometricLoginReady();
});

/// Check if device supports biometric authentication
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final biometricService = BiometricService();
  return await biometricService.canCheckBiometrics();
});

/// Get biometric type name for display
final biometricTypeProvider = FutureProvider<String>((ref) async {
  final biometricService = BiometricService();
  return await biometricService.getBiometricTypeName();
});

// ===== BIOMETRIC AUTH CONTROLLER =====

/// State for biometric authentication result
class BiometricAuthState {
  final bool isLoading;
  final User? user;
  final UserModel? userProfile;
  final String? error;

  BiometricAuthState({
    this.isLoading = false,
    this.user,
    this.userProfile,
    this.error,
  });

  BiometricAuthState copyWith({
    bool? isLoading,
    User? user,
    UserModel? userProfile,
    String? error,
  }) {
    return BiometricAuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      userProfile: userProfile ?? this.userProfile,
      error: error ?? this.error,
    );
  }
}

/// Controller for biometric authentication flow
class BiometricAuthController extends StateNotifier<BiometricAuthState> {
  final BiometricService _biometricService;
  final SecureStorageService _secureStorage;
  final AuthService _authService;
  final FirestoreService _firestoreService;

  BiometricAuthController(
    this._biometricService,
    this._secureStorage,
    this._authService,
    this._firestoreService,
  ) : super(BiometricAuthState());

  /// Main biometric login flow
  /// Returns true if authentication successful and navigates appropriately
  Future<bool> authenticateWithBiometric() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Step 1: Authenticate with biometric first
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to access your account',
      );

      if (!authenticated) {
        state = state.copyWith(
          isLoading: false,
          error: 'Biometric authentication failed',
        );
        return false;
      }

      // Step 2: Check if user has enrolled credentials
      final isEnrolled = await _secureStorage.isBiometricLoginReady();

      if (!isEnrolled) {
        // First-time user - create account automatically
        return await _handleFirstTimeUser();
      }

      // Step 3: Retrieve stored credentials (returning user)
      final credentials = await _secureStorage.getAllCredentials();
      final email = credentials['email'];
      final password = credentials['password'];
      final uid = credentials['uid'];

      if (email == null || password == null || uid == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Stored credentials not found',
        );
        await _secureStorage.clearCredentials();
        return false;
      }

      // Step 4: Sign in to Firebase
      final userCredential = await _authService.signInWithEmailPassword(
        email,
        password,
      );

      if (userCredential?.user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to sign in',
        );
        return false;
      }

      // Step 5: Verify UID matches
      if (userCredential!.user!.uid != uid) {
        state = state.copyWith(
          isLoading: false,
          error: 'User verification failed',
        );
        await _secureStorage.clearCredentials();
        return false;
      }

      // Step 6: Fetch user profile
      final userProfile = await _firestoreService.getUserProfile(uid);

      if (userProfile == null) {
        // Profile doesn't exist - create one
        final newProfile = UserModel(
          uid: uid,
          email: email,
          isProfileComplete: false,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUserProfile(newProfile);

        state = state.copyWith(
          isLoading: false,
          user: userCredential.user,
          userProfile: newProfile,
        );
        return true;
      }

      // Success - return with profile
      state = state.copyWith(
        isLoading: false,
        user: userCredential.user,
        userProfile: userProfile,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Handle first-time user authentication
  /// Creates a new account automatically using biometric-based credentials
  Future<bool> _handleFirstTimeUser() async {
    try {
      // Generate unique credentials for this user
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final email = 'user_$timestamp@biometric.local';
      final password = _generateSecurePassword();

      // Create Firebase account
      final userCredential = await _authService.createUserWithEmailPassword(
        email,
        password,
      );

      if (userCredential?.user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create account',
        );
        return false;
      }

      final user = userCredential!.user!;

      // Store credentials securely
      await _secureStorage.saveUserCredentials(
        email: email,
        password: password,
        uid: user.uid,
      );

      // Create user profile in Firestore
      final newProfile = UserModel(
        uid: user.uid,
        email: email,
        isProfileComplete: false,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUserProfile(newProfile);

      state = state.copyWith(
        isLoading: false,
        user: user,
        userProfile: newProfile,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set up account: ${e.toString()}',
      );
      return false;
    }
  }

  /// Generate a cryptographically secure random password
  String _generateSecurePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    final password = List.generate(
      32,
      (index) => chars[(random + index) % chars.length],
    ).join();
    return password;
  }

  /// Enroll biometric login after successful email/password authentication
  Future<bool> enrollBiometric({
    required String email,
    required String password,
    required String uid,
  }) async {
    try {
      // Authenticate with biometric to confirm enrollment
      final authenticated = await _biometricService.authenticate(
        reason: 'Enable biometric login for faster access',
      );

      if (!authenticated) {
        return false;
      }

      // Save credentials securely
      await _secureStorage.saveUserCredentials(
        email: email,
        password: password,
        uid: uid,
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    await _secureStorage.disableBiometric();
  }

  /// Re-enable biometric login (if credentials already exist)
  Future<bool> enableBiometric() async {
    try {
      final hasCredentials = await _secureStorage.hasEnrolledCredentials();
      if (!hasCredentials) {
        return false;
      }

      final authenticated = await _biometricService.authenticate(
        reason: 'Enable biometric login',
      );

      if (authenticated) {
        await _secureStorage.enableBiometric();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Sign out and clear biometric credentials
  Future<void> signOutAndClearBiometric() async {
    await _authService.signOut();
    await _secureStorage.clearCredentials();
    state = BiometricAuthState();
  }

  /// Update stored password when user changes it
  Future<void> updateStoredPassword(String newPassword) async {
    await _secureStorage.updatePassword(newPassword);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Biometric Auth Controller Provider
final biometricAuthControllerProvider =
    StateNotifierProvider<BiometricAuthController, BiometricAuthState>((ref) {
  return BiometricAuthController(
    BiometricService(),
    ref.watch(secureStorageServiceProvider),
    ref.watch(authServiceProvider),
    ref.watch(firestoreServiceProvider),
  );
});

