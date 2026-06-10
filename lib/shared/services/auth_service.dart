import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import 'company_service.dart';

/// Enhanced authentication service for multi-tenant system
/// Supports: Super Admin, Company Admin, Supervisor, Employee
class AuthService {
  /// Name used for the secondary Firebase app that handles user creation
  /// without disturbing the currently signed-in user's session.
  static const String _kSecondaryAppName = 'SecondaryUserCreatorApp';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CompanyService _companyService = CompanyService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================
  // MULTI-TENANT SIGN IN
  // ============================================

  /// Sign in SUPER ADMIN (no company code needed)
  Future<UserCredential> signInSuperAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user is super admin
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw 'User data not found';
      }

      final role = userDoc.data()?['role'] as String?;
      if (role != 'superadmin') {
        await _auth.signOut();
        throw 'Access denied: Not a super admin account';
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }
  }

  /// Sign in COMPANY ADMIN or SUPERVISOR (requires company code)
  Future<UserCredential> signInWithCompany({
    required String companyCode,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Validate company code exists
      final company = await _companyService.getCompanyByCode(companyCode);
      if (company == null) {
        throw 'Invalid company code: $companyCode';
      }

      if (!company.isActive) {
        throw 'Company is suspended. Please contact support.';
      }

      // 2. Sign in with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Verify user belongs to this company
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw 'User data not found';
      }

      final userData = userDoc.data()!;
      final userCompanyId = userData['companyId'] as String?;
      final role = userData['role'] as String?;
      final status = (userData['status'] as String?)?.toLowerCase();

      if (userCompanyId != company.id) {
        await _auth.signOut();
        throw 'User does not belong to company: $companyCode';
      }

      // Verify role is company admin or supervisor
      if (role != 'companyadmin' && role != 'supervisor' && role != 'admin') {
        await _auth.signOut();
        throw 'Invalid account type. Use employee login instead.';
      }

      if (status == 'pending') {
        await _auth.signOut();
        throw 'Account pending company admin approval.';
      }

      if (status == 'suspended' || status == 'inactive' || status == 'rejected') {
        await _auth.signOut();
        throw 'Account is not active. Please contact your company admin.';
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }
  }

  /// Sign in EMPLOYEE (no Firebase Auth - uses Firestore only)
  /// Returns UserModel if successful
  Future<UserModel> signInEmployee({
    required String companyCode,
    required String employeeId,
  }) async {
    try {
      // 1. Validate company code exists
      final company = await _companyService.getCompanyByCode(companyCode);
      if (company == null) {
        throw 'Invalid company code: $companyCode';
      }

      if (!company.isActive) {
        throw 'Company is suspended. Please contact support.';
      }

      // 2. Format employee ID (accept both 0001 and ABC-0001)
      String formattedId = employeeId.trim();
      if (!formattedId.contains('-')) {
        // Add company prefix if not provided
        formattedId = '${company.companyCode}-$formattedId';
      }

      // 3. Query employee by employeeId and companyId
      final querySnapshot = await _firestore
          .collection('users')
          .where('companyId', isEqualTo: company.id)
          .where('employeeId', isEqualTo: formattedId)
          .where('role', isEqualTo: 'employee')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'Employee not found: $employeeId';
      }

      final userData = querySnapshot.docs.first.data();
      final user = UserModel.fromMap(userData);

      // 4. Check status
      if (user.isPending) {
        throw 'Account pending approval. Please contact your supervisor.';
      }

      if (user.isSuspended) {
        throw 'Account suspended. Please contact your supervisor.';
      }

      if (!user.isApproved && !user.isActive) {
        throw 'Account not activated. Please contact your supervisor.';
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // SIGN UP (Admin/Supervisor creation)
  // ============================================

  /// Create company admin or supervisor account
  ///
  /// Uses a *secondary* Firebase app instance to create the Auth user so
  /// the currently signed-in user is NOT replaced by the new account.
  /// Without this workaround, calling `createUserWithEmailAndPassword` on
  /// the default auth instance would sign the new user in immediately and
  /// log out the current admin/supervisor.
  Future<UserCredential> createCompanyUser({
    required String companyId,
    required String email,
    required String password,
    required String role, // 'companyadmin' or 'supervisor'
  }) async {
    try {
      // Validate role
      if (role != 'companyadmin' && role != 'supervisor') {
        throw 'Invalid role for company user';
      }

      // Validate company exists
      final company = await _companyService.getCompany(companyId);
      if (company == null) {
        throw 'Company not found';
      }

      // Get or create a secondary Firebase app so the new user's session
      // is isolated from the current signed-in user's session.
      final FirebaseApp secondaryApp = await _getOrCreateSecondaryApp();
      final FirebaseAuth secondaryAuth =
          FirebaseAuth.instanceFor(app: secondaryApp);

      try {
        // Create the Firebase Auth account on the *secondary* auth
        // instance. This signs in as the new user on the secondary app
        // only, leaving the main app's auth state untouched.
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        return credential;
      } finally {
        // Clean up the secondary session so the next call starts fresh.
        try {
          await secondaryAuth.signOut();
        } catch (_) {
          // Best-effort cleanup; ignore errors here.
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Returns an existing secondary Firebase app or initialises a new one.
  /// The secondary app reuses the default app's Firebase options.
  Future<FirebaseApp> _getOrCreateSecondaryApp() async {
    try {
      return Firebase.app(_kSecondaryAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _kSecondaryAppName,
        options: Firebase.app().options,
      );
    }
  }

  /// Create super admin account (platform owner)
  Future<UserCredential> createSuperAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // PASSWORD MANAGEMENT
  // ============================================

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email: $e';
    }
  }

  /// Update password for current user
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'No user signed in';
      }

      // Re-authenticate before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to update password: $e';
    }
  }

  // ============================================
  // SIGN OUT
  // ============================================

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out: $e';
    }
  }

  // ============================================
  // VALIDATION HELPERS
  // ============================================

  /// Validate company code format
  bool isValidCompanyCode(String code) {
    return RegExp(r'^[A-Z]{3,6}$').hasMatch(code.toUpperCase());
  }

  /// Validate employee ID format (accepts both 0001 and ABC-0001)
  bool isValidEmployeeId(String id) {
    // Accept 4-digit number or PREFIX-NUMBER format
    return RegExp(r'^\d{4}$').hasMatch(id) ||
        RegExp(r'^[A-Z]{3,6}-\d{4}$').hasMatch(id.toUpperCase());
  }

  /// Check if email format is valid
  bool isValidEmail(String email) {
    final regex = RegExp(AppConstants.emailRegex);
    return regex.hasMatch(email);
  }

  /// Check if password meets requirements
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Stream user data from Firestore
  Stream<UserModel?> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  /// Handle Firebase Auth exceptions with user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email/ID';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support';
      case 'requires-recent-login':
        return 'Please sign in again to continue';
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  /// Generate secure random password
  String generateSecurePassword({int length = 16}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) {
      final seed = (random + index) % chars.length;
      return chars[seed];
    }).join();
  }

  // ============================================
  // ACCOUNT MANAGEMENT
  // ============================================

  /// Delete current user account
  Future<void> deleteAccount({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'No user signed in';
      }

      // Re-authenticate before deleting
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to delete account: $e';
    }
  }

  /// Re-authenticate user (useful before sensitive operations)
  Future<void> reauthenticate({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'No user signed in';
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Re-authentication failed: $e';
    }
  }
}
