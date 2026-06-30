import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/device_service.dart';
import '../services/employee_session_storage.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

// ============================================
// SERVICE PROVIDERS
// ============================================

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Device service provider
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

final employeeSessionStorageProvider = Provider<EmployeeSessionStorage>((ref) {
  return EmployeeSessionStorage();
});

// ============================================
// AUTH STATE PROVIDERS
// ============================================

/// Firebase auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current user ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});

// ============================================
// USER DATA PROVIDER
// ============================================

/// Current user profile provider
/// For supervisors/admins: Uses Firebase Auth state with real-time Firestore listener
/// For employees: Uses auth controller state (no Firebase Auth)
final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  // First check if auth controller has a user (for employees without Firebase Auth)
  final authControllerState = ref.watch(authControllerProvider);
  if (authControllerState.user != null) {
    print('✅ Using user from auth controller state (employee login)');
    // Still subscribe to real-time updates for employee data changes
    final firestoreService = ref.watch(firestoreServiceProvider);
    final userId = authControllerState.user!.uid;
    if (userId.isNotEmpty) {
      yield* firestoreService.streamUser(userId);
    } else {
      yield authControllerState.user;
    }
    return;
  }

  // Otherwise, use Firebase Auth state (for supervisors/admins)
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;
  print('userId: $userId');
  if (userId == null) {
    yield null;
    return;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);

  // Use real-time stream instead of one-time get
  try {
    await for (final user in firestoreService.streamUser(userId)) {
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('👤 CURRENT USER UPDATED (Real-time)');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (user != null) {
        print('  - UID: ${user.uid}');
        print('  - Name: ${user.name}');
        print('  - Role: ${user.role}');
        print('  - CompanyId: ${user.companyId ?? "NULL"}');
        print('  - Email: ${user.email}');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      yield user;
    }
  } catch (e) {
    print('❌ Error fetching user: $e');
    yield null;
  }
});

/// User role provider
final userRoleProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.value?.role;
});

/// Is employee provider
final isEmployeeProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'employee';
});

/// Is supervisor provider
final isSupervisorProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'supervisor';
});

/// Is admin provider
final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'admin' || role == 'companyadmin' || role == 'superadmin';
});

// ============================================
// AUTH CONTROLLER
// ============================================

/// Authentication state
class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

/// Authentication controller
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final EmployeeSessionStorage _employeeSession;
  final DeviceService _deviceService;

  AuthController(
    this._authService,
    this._firestoreService,
    this._employeeSession,
    this._deviceService,
  ) : super(const AuthState());

  /// Restore employee from secure storage (same device, still approved).
  /// Call on app launch before role selection.
  Future<bool> restoreEmployeeSessionIfValid() async {
    try {
      final uid = await _employeeSession.readPersistedEmployeeUid();
      if (uid == null || uid.isEmpty) return false;

      final user = await _firestoreService.getUser(uid);
      if (user == null ||
          user.role != AppConstants.roleEmployee ||
          (!user.isApproved && !user.isActive)) {
        await _employeeSession.clearPersistedEmployee();
        return false;
      }

      var resolved = user.uid.isEmpty ? user.copyWith(uid: uid) : user;

      if (resolved.deviceInfo == null && resolved.uid.isNotEmpty) {
        try {
          final deviceInfo = await _deviceService.getDeviceInfo();
          if (deviceInfo != null) {
            await _firestoreService.updateUser(resolved.uid, {
              'deviceInfo': deviceInfo.toMap(),
            });
            resolved = resolved.copyWith(deviceInfo: deviceInfo);
          }
        } catch (e) {
          print('restoreEmployeeSession device bind: $e');
        }
      }

      final registered = resolved.deviceInfo;
      if (registered != null) {
        final currentId = await _deviceService.getDeviceId();
        if (registered.deviceId != currentId) {
          await _employeeSession.clearPersistedEmployee();
          return false;
        }
      }

      state = state.copyWith(user: resolved);
      return true;
    } catch (e) {
      print('restoreEmployeeSessionIfValid: $e');
      await _employeeSession.clearPersistedEmployee();
      return false;
    }
  }

  /// Sign in with email and password (for company admin/supervisor)
  /// Note: This is a legacy method. For multi-tenant, use signInWithCompany in auth service directly
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use Firebase Auth directly for backward compatibility
      final firebaseAuth = FirebaseAuth.instance;
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Sign in failed',
        );
        return false;
      }

      // Get user profile
      final user = await _firestoreService.getUser(credential.user!.uid);

      state = state.copyWith(
        isLoading: false,
        user: user,
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

  /// Sign in with employee ID and PIN (Firestore lookup, no Firebase Auth)
  Future<bool> signInWithEmployeeId({
    required String employeeId,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔑 EMPLOYEE LOGIN ATTEMPT');
      print('  Employee ID: $employeeId');
      print('  PIN: $password');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Lookup employee in Firestore by ID and validate PIN
      // Employees don't have Firebase Auth accounts!
      final user = await _firestoreService.getEmployeeByIdAndPin(
        employeeId: employeeId,
        pin: password,
      );

      if (user == null) {
        print('❌ Employee not found or PIN invalid');
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid Employee ID or PIN',
        );
        return false;
      }

      print('✅ Employee login successful: ${user.name}');
      print('  Status: ${user.status}');
      print('  UID: ${user.uid}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Set user in state (no Firebase Auth credential needed)
      state = state.copyWith(
        isLoading: false,
        user: user,
      );

      if (user.uid.isNotEmpty) {
        await _employeeSession.savePersistedEmployeeUid(user.uid);
      }

      return true;
    } catch (e) {
      print('❌ Employee login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _employeeSession.clearPersistedEmployee();
      await _authService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final employeeSession = ref.watch(employeeSessionStorageProvider);
  final deviceService = ref.watch(deviceServiceProvider);
  return AuthController(
    authService,
    firestoreService,
    employeeSession,
    deviceService,
  );
});

// ============================================
// ADMIN PROVIDERS (For Web Dashboard)
// Real-time streams for immediate UI updates
// ============================================

/// Provider for all supervisors (real-time)
final allSupervisorsProvider = StreamProvider<List<UserModel>>((ref) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  try {
    if (currentUser == null) {
      yield [];
      return;
    }
    // Super admin sees all supervisors; others see only their company's supervisors
    if (currentUser.role == 'superadmin') {
      yield* firestoreService.streamUsersByRole('supervisor');
    } else if (currentUser.companyId != null) {
      yield* firestoreService.streamUsersByRoleForCompany(
        role: 'supervisor',
        companyId: currentUser.companyId!,
      );
    } else {
      yield [];
    }
  } catch (e) {
    print('Error fetching supervisors stream: $e');
    yield [];
  }
});

/// Provider for all pending employees (real-time, not yet approved)
final allPendingEmployeesProvider =
    StreamProvider<List<UserModel>>((ref) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  try {
    if (currentUser == null) {
      yield [];
      return;
    }
    if (currentUser.role == 'superadmin') {
      yield* firestoreService.streamAllPendingEmployees();
    } else if (currentUser.companyId != null) {
      yield* firestoreService.streamPendingEmployeesForCompany(
        currentUser.companyId!,
      );
    } else {
      yield [];
    }
  } catch (e) {
    print('Error fetching pending employees stream: $e');
    yield [];
  }
});

/// Provider for all approved employees (real-time)
final allApprovedEmployeesProvider =
    StreamProvider<List<UserModel>>((ref) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  try {
    if (currentUser == null) {
      yield [];
      return;
    }
    if (currentUser.role == 'superadmin') {
      yield* firestoreService.streamAllApprovedEmployees();
    } else if (currentUser.companyId != null) {
      yield* firestoreService.streamApprovedEmployeesForCompany(
        currentUser.companyId!,
      );
    } else {
      yield [];
    }
  } catch (e) {
    print('Error fetching approved employees stream: $e');
    yield [];
  }
});
