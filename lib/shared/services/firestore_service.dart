import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../models/attendance_model.dart';
import '../models/document_model.dart';
import '../models/device_reset_request_model.dart';
import '../models/audit_log_model.dart';
import '../constants/app_constants.dart';

/// Service for all Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Set<String>> _resolveCompanyFilterKeys(String companyId) async {
    final keys = <String>{companyId};
    final normalizedInput = companyId.trim().toUpperCase();
    if (normalizedInput.isNotEmpty) {
      keys.add(normalizedInput);
    }

    // Resolve company by document id (legacy/random or code-based).
    final byId = await _firestore.collection('companies').doc(companyId).get();
    if (byId.exists) {
      final data = byId.data();
      final code = (data?['companyCode'] as String?)?.trim().toUpperCase();
      if (code != null && code.isNotEmpty) {
        keys.add(code);
      }
      final docId = byId.id.trim();
      if (docId.isNotEmpty) {
        keys.add(docId);
        keys.add(docId.toUpperCase());
      }
    }

    // Resolve all company docs sharing the same company code.
    if (normalizedInput.isNotEmpty) {
      final byCode = await _firestore
          .collection('companies')
          .where('companyCode', isEqualTo: normalizedInput)
          .get();
      for (final doc in byCode.docs) {
        final docId = doc.id.trim();
        if (docId.isNotEmpty) {
          keys.add(docId);
          keys.add(docId.toUpperCase());
        }
        final code = (doc.data()['companyCode'] as String?)?.trim().toUpperCase();
        if (code != null && code.isNotEmpty) {
          keys.add(code);
        }
      }
    }

    return keys;
  }

  // ============================================
  // USER OPERATIONS
  // ============================================

  /// Create new user profile
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      throw 'Failed to create user: $e';
    }
  }

  /// Get user profile by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      throw 'Failed to get user: $e';
    }
  }

  /// Update user profile
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updates);
    } catch (e) {
      throw 'Failed to update user: $e';
    }
  }

  /// Delete a user and clean related references in projects and reporting links.
  Future<void> deleteUserAndCleanup(
    UserModel user, {
    String? replacementSupervisorId,
  }) async {
    try {
      final userRef =
          _firestore.collection(AppConstants.usersCollection).doc(user.uid);

      // Remove this user from any project's assigned employee lists.
      final assignedProjects = await _firestore
          .collection(AppConstants.projectsCollection)
          .where('assignedEmployeeIds', arrayContains: user.uid)
          .get();

      for (final doc in assignedProjects.docs) {
        final projectRef =
            _firestore.collection(AppConstants.projectsCollection).doc(doc.id);
        await projectRef.update({
          'assignedEmployeeIds': FieldValue.arrayRemove([user.uid]),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Best effort cleanup of assignedEmployees subcollection membership row.
        await projectRef
            .collection(AppConstants.assignedEmployeesSubcollection)
            .doc(user.uid)
            .delete()
            .catchError((_) {});
      }

      // If deleting a supervisor, clear project ownership and employee links.
      if (user.role == 'supervisor') {
        final supervisedProjects = await _firestore
            .collection(AppConstants.projectsCollection)
            .where('supervisorId', isEqualTo: user.uid)
            .get();

        for (final doc in supervisedProjects.docs) {
          await _firestore
              .collection(AppConstants.projectsCollection)
              .doc(doc.id)
              .update({
            'supervisorId': replacementSupervisorId,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }

        final supervisedEmployees = await _firestore
            .collection(AppConstants.usersCollection)
            .where('supervisorId', isEqualTo: user.uid)
            .get();

        for (final doc in supervisedEmployees.docs) {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(doc.id)
              .update({
            'supervisorId': replacementSupervisorId,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }

      await userRef.delete();
    } catch (e) {
      throw 'Failed to delete user: $e';
    }
  }

  /// Get all employees (for supervisors/admins) - filtered by company
  Future<List<UserModel>> getAllEmployees() async {
    try {
      // Get current user's companyId for filtering
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      final role = userData['role'] as String?;
      final companyId = userData['companyId'] as String?;
      
      // Super admin sees all employees
      if (role == 'superadmin') {
        final snapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .where('role', isEqualTo: AppConstants.roleEmployee)
            .get();
        return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      }
      
      // Company admin/supervisor see only their company's employees
      if (companyId == null) {
        print('⚠️ Warning: User has no companyId, returning empty employees list');
        return [];
      }
      
      final companyKeys = await _resolveCompanyFilterKeys(companyId);
      print('✅ Fetching employees for company keys: $companyKeys');

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleEmployee)
          .get();

      final employees = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) => user.companyId != null && companyKeys.contains(user.companyId))
          .toList();

      print('✅ Found ${employees.length} employees for company');
      return employees;
    } catch (e) {
      throw 'Failed to get employees: $e';
    }
  }

  /// Get all users (employees, supervisors, admins) - for admin dashboard - filtered by company
  Future<List<UserModel>> getAllUsers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return [];
      }

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data()!;
      final role = userData['role'] as String?;
      final companyId = userData['companyId'] as String?;

      final users = <UserModel>[];

      if (role == 'superadmin') {
        final snapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .get();

        for (final doc in snapshot.docs) {
          try {
            final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
            users.add(user);
          } catch (e) {
            print('Error parsing user document ${doc.id}: $e');
            print('   Data: ${doc.data()}');
          }
        }
      } else {
        if (companyId == null) {
          print('Warning: User has no companyId, returning empty users list');
          return [];
        }

        final companyKeys = await _resolveCompanyFilterKeys(companyId);
        print('Fetching users for company keys: $companyKeys');

        final allUsersSnapshot =
            await _firestore.collection(AppConstants.usersCollection).get();

        for (final doc in allUsersSnapshot.docs) {
          final data = doc.data();
          final userCompanyId = data['companyId'] as String?;
          if (userCompanyId == null || !companyKeys.contains(userCompanyId)) {
            continue;
          }

          try {
            final user = UserModel.fromMap(data as Map<String, dynamic>);
            users.add(user);
          } catch (e) {
            print('Error parsing user document ${doc.id}: $e');
            print('   Data: ${doc.data()}');
          }
        }
      }

      users.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      print('Found ${users.length} users for company');
      return users;
    } catch (e) {
      throw 'Failed to get all users: $e';
    }
  }

  /// SA-6: Get users for a specific company (for super admin troubleshooting)
  Future<List<UserModel>> getUsersByCompanyId(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('companyId', isEqualTo: companyId)
          .get();

      final users = <UserModel>[];
      for (final doc in snapshot.docs) {
        try {
          final user = UserModel.fromMap(doc.data());
          users.add(user);
        } catch (e) {
          print('⚠️ Error parsing user document ${doc.id}: $e');
        }
      }

      users.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return users;
    } catch (e) {
      throw 'Failed to get users by company: $e';
    }
  }

  /// SA-5: Get all projects for a specific company (for super admin reports)
  Future<List<ProjectModel>> getProjectsByCompanyId(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.projectsCollection)
          .where('companyId', isEqualTo: companyId)
          .get();

      return snapshot.docs.map((doc) => ProjectModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw 'Failed to get projects by company: $e';
    }
  }

  /// SA-5: Get attendance records for all employees in a specific company within a date range
  Future<List<AttendanceModel>> getAttendanceByCompanyAndDateRange(
    String companyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allAttendance = <AttendanceModel>[];

      // Get all employees in this company
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('companyId', isEqualTo: companyId)
          .where('role', isEqualTo: AppConstants.roleEmployee)
          .get();

      for (final userDoc in usersSnapshot.docs) {
        final attendanceSnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userDoc.id)
            .collection(AppConstants.attendanceSubcollection)
            .where('checkInTime',
                isGreaterThanOrEqualTo: startDate.toIso8601String())
            .where('checkInTime',
                isLessThanOrEqualTo: endDate.toIso8601String())
            .get();

        for (final doc in attendanceSnapshot.docs) {
          allAttendance.add(AttendanceModel.fromMap(doc.data()));
        }
      }

      allAttendance.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return allAttendance;
    } catch (e) {
      throw 'Failed to get attendance by company and date range: $e';
    }
  }

  /// SA-5: Get all attendance records for employees in a specific company for a given project
  Future<List<AttendanceModel>> getAttendanceByCompanyAndProject(
    String companyId,
    String projectId,
  ) async {
    try {
      final allAttendance = <AttendanceModel>[];

      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('companyId', isEqualTo: companyId)
          .where('role', isEqualTo: AppConstants.roleEmployee)
          .get();

      for (final userDoc in usersSnapshot.docs) {
        final attendanceSnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userDoc.id)
            .collection(AppConstants.attendanceSubcollection)
            .where('projectId', isEqualTo: projectId)
            .get();

        for (final doc in attendanceSnapshot.docs) {
          allAttendance.add(AttendanceModel.fromMap(doc.data()));
        }
      }

      allAttendance.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return allAttendance;
    } catch (e) {
      throw 'Failed to get attendance by company and project: $e';
    }
  }

  /// SA-5: Get all attendance records for a specific employee (by userId)
  Future<List<AttendanceModel>> getAttendanceByEmployee(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.attendanceSubcollection)
          .orderBy('checkInTime', descending: true)
          .get();

      return snapshot.docs.map((doc) => AttendanceModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw 'Failed to get attendance by employee: $e';
    }
  }

  /// Get pending employees (for admin approval) - filtered by company
  Future<List<UserModel>> getPendingEmployees() async {
    try {
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔍 GET PENDING EMPLOYEES - START');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Get current user's companyId for filtering
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return [];
      }
      
      print('✅ Current Firebase User: ${currentUser.uid}');
      print('✅ Email: ${currentUser.email}');
      
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        print('❌ User document not found in Firestore');
        print('   Path checked: users/${currentUser.uid}');
        return [];
      }
      
      final userData = userDoc.data()!;
      final role = userData['role'] as String?;
      final companyId = userData['companyId'] as String?;
      
      print('✅ User Role: $role');
      print('✅ User CompanyId: ${companyId ?? "NULL"}');
      
      if (companyId == null || companyId.isEmpty) {
        print('❌ CRITICAL: Admin has NO companyId!');
        print('   Admin user document:');
        print('   ${userData.toString()}');
        return [];
      }
      
      // Super admin sees all pending employees and supervisors
      if (role == 'superadmin') {
        print('🔑 User is SUPER ADMIN - fetching ALL pending employees and supervisors');
        final snapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .where('status', isEqualTo: AppConstants.statusPending)
            .where('role', whereIn: [AppConstants.roleEmployee, AppConstants.roleSupervisor])
            .orderBy('createdAt', descending: true)
            .get();
        
        print('✅ Found ${snapshot.docs.length} total pending users (super admin view)');
        return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      }
      
      print('🏢 Fetching pending employees and supervisors for COMPANY: $companyId');
      print('📋 Query Details:');
      print('   - Collection: users');
      print('   - role in ["employee", "supervisor"]');
      print('   - companyId = "$companyId"');
      print('   - status = "pending"');
      
      // ✅ Query with company filter
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('status', isEqualTo: AppConstants.statusPending)
          .where('role', whereIn: [AppConstants.roleEmployee, AppConstants.roleSupervisor])
          .orderBy('createdAt', descending: true)
          .get();
      
      print('');
      print('📊 INITIAL QUERY RESULTS (Before Company Filter):');
      print('   Total pending users found: ${snapshot.docs.length}');
      
      // Filter by companyId (handles both old and new format)
      final filteredUsers = <QueryDocumentSnapshot>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userCompanyId = data['companyId'] as String?;
        final userName = data['name'] as String? ?? 'Unknown';
        final userId = data['employeeId'] ?? data['systemGeneratedId'] ?? data['customId'] ?? 'N/A';
        final userStatus = data['status'] as String?;
        final userRole = data['role'] as String?;
        
        print('');
        print('   Checking: $userName ($userId)');
        print('      - UID: ${doc.id}');
        print('      - User CompanyId: "${userCompanyId ?? "NULL"}"');
        print('      - Admin CompanyId: "$companyId"');
        print('      - Status: $userStatus');
        print('      - Role: $userRole');
        
        // Match if companyId exactly matches
        if (userCompanyId == companyId) {
          print('      ✅ MATCH! User belongs to admin\'s company');
          filteredUsers.add(doc);
        } else {
          print('      ❌ NO MATCH! Different company');
          print('         User: "${userCompanyId ?? "NULL"}"');
          print('         Admin: "$companyId"');
        }
      }

      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 FINAL RESULT:');
      print('   Total pending users (all): ${snapshot.docs.length}');
      print('   Filtered for company "$companyId": ${filteredUsers.length}');
      
      if (filteredUsers.isEmpty) {
        print('');
        print('⚠️ NO PENDING USERS FOUND FOR COMPANY "$companyId"!');
        print('');
        print('🔍 DIAGNOSTIC INFORMATION:');
        print('   1. Admin CompanyId: "$companyId"');
        print('   2. Total pending users (all companies): ${snapshot.docs.length}');
        
        if (snapshot.docs.isNotEmpty) {
          print('');
          print('   Pending users that exist (other companies):');
          for (var doc in snapshot.docs) {
            final data = doc.data();
            print('      - ${data['name']} (${data['role']}): companyId="${data['companyId'] ?? "NULL"}"');
          }
          
          print('');
          print('   💡 POSSIBLE ISSUES:');
          print('      • Admin companyId ("$companyId") doesn\'t match any user');
          print('      • Users were created with different companyId');
          print('      • Check Firestore console to verify companyId fields');
        } else {
          print('   No pending users exist in the entire system');
        }
      } else {
        print('');
        print('   ✅ Matching users:');
        for (var doc in filteredUsers) {
          final data = doc.data() as Map<String, dynamic>;
          print('      - ${data['name']} (${data['employeeId'] ?? data['systemGeneratedId'] ?? data['customId']}) [${data['role']}]');
        }
      }
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔍 GET PENDING EMPLOYEES - END');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      
      return filteredUsers.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e, stackTrace) {
      print('');
      print('❌ ERROR in getPendingEmployees: $e');
      print('Stack trace: $stackTrace');
      throw 'Failed to get pending employees: $e';
    }
  }

  /// Get employees by supervisor - already filtered by supervisorId (implicit company filtering)
  Future<List<UserModel>> getEmployeesBySupervisor(String supervisorId) async {
    try {
      // Note: Since employees are assigned to supervisors, and supervisors belong to companies,
      // this query is implicitly company-specific (supervisor can only see their own employees)
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleEmployee)
          .where('supervisorId', isEqualTo: supervisorId)
          .get();

      print('✅ Found ${snapshot.docs.length} employees for supervisor: $supervisorId');
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw 'Failed to get employees by supervisor: $e';
    }
  }

  /// Get approved employees - filtered by company
  Future<List<UserModel>> getApprovedEmployees() async {
    try {
      // Get current user's companyId for filtering
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      final role = userData['role'] as String?;
      final companyId = userData['companyId'] as String?;
      
      // Super admin sees all approved employees
      if (role == 'superadmin') {
        final snapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .where('role', isEqualTo: AppConstants.roleEmployee)
            .where('status', whereIn: [AppConstants.statusApproved, AppConstants.statusActive])
            .get();
        return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      }
      
      // Company admin/supervisor see only their company's approved employees
      if (companyId == null) {
        print('⚠️ Warning: User has no companyId, returning empty approved employees list');
        return [];
      }
      
      print('✅ Fetching approved employees for company: $companyId');
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleEmployee)
          .where('companyId', isEqualTo: companyId)
          .where('status', whereIn: [AppConstants.statusApproved, AppConstants.statusActive])
          .get();

      print('✅ Found ${snapshot.docs.length} approved employees for company');
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw 'Failed to get approved employees: $e';
    }
  }

  /// Get users by role - filtered by company
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      // Get current user's companyId for filtering
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      final userRole = userData['role'] as String?;
      final companyId = userData['companyId'] as String?;
      
      // Super admin sees all users of specified role
      if (userRole == 'superadmin') {
        final snapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .where('role', isEqualTo: role)
            .get();
        return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      }
      
      // Company admin/supervisor see only their company's users of specified role
      if (companyId == null) {
        print('⚠️ Warning: User has no companyId, returning empty users list');
        return [];
      }
      
      print('✅ Fetching $role users for company: $companyId');
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: role)
          .where('companyId', isEqualTo: companyId)
          .get();

      print('✅ Found ${snapshot.docs.length} $role users for company');
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw 'Failed to get users by role: $e';
    }
  }

  /// Get employee by ID and validate PIN (for employee login)
  /// Returns UserModel if found and PIN matches, null otherwise
  Future<UserModel?> getEmployeeByIdAndPin({
    required String employeeId,
    required String pin,
  }) async {
    try {
      final normalizedInput = employeeId.trim().toUpperCase();
      if (normalizedInput.isEmpty) {
        return null;
      }

      // Strict format to prevent ambiguity across companies.
      // Accepted format: COMPANYCODE-EMPLOYEEID (e.g. ABC-0001).
      if (!normalizedInput.contains('-')) {
        throw 'Please login with CompanyCode-EmployeeID (example: ABC-0001).';
      }

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleEmployee)
          .where('employeeId', isEqualTo: normalizedInput)
          .limit(2)
          .get();

      final matchedDocs = snapshot.docs;

      if (matchedDocs.isEmpty) {
        print('❌ Employee not found: $normalizedInput');
        return null;
      }

      if (matchedDocs.length > 1) {
        throw 'Multiple employees found for this Employee ID. Contact support to resolve duplicate employee records.';
      }

      final doc = matchedDocs.first;
      final data = doc.data() as Map<String, dynamic>;
      var user = UserModel.fromMap(data);
      // Ensure uid is the Firestore document ID (required for getEmployeeProjects and .doc(uid) lookups)
      if (user.uid.isEmpty) {
        user = user.copyWith(uid: doc.id);
        print('   📌 Using document ID as uid: ${doc.id}');
      }

      // Check status - must be approved
      if (user.status != AppConstants.statusApproved && 
          user.status != AppConstants.statusActive) {
        print('❌ Employee not approved: status=${user.status}');
        throw 'Employee account is not approved. Status: ${user.status}';
      }

      // Validate PIN from Firestore document
      final storedPin = data['pin'] as String?;
      if (storedPin == null || storedPin != pin) {
        print('❌ PIN mismatch: stored=$storedPin, provided=$pin');
        throw 'Invalid PIN';
      }

      print('✅ Employee found and PIN validated: ${user.name} (uid: ${user.uid})');
      return user;
    } catch (e) {
      print('❌ Error looking up employee: $e');
      rethrow;
    }
  }

  /// Validate whether a custom ID is unique within a company.
  /// Duplicate custom IDs are blocked for employees, supervisors, and company admins.
  Future<bool> isCustomIdAvailable({
    required String companyId,
    required String customId,
    String? excludeUserId,
  }) async {
    try {
      final normalizedCustomId = customId.trim().toUpperCase();
      if (normalizedCustomId.isEmpty) return false;

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('companyId', isEqualTo: companyId)
          .get();

      for (final doc in snapshot.docs) {
        if (excludeUserId != null && doc.id == excludeUserId) {
          continue;
        }
        final data = doc.data();
        final role = data['role'] as String?;
        if (role != AppConstants.roleEmployee &&
            role != AppConstants.roleSupervisor &&
            role != AppConstants.roleAdmin &&
            role != 'companyadmin') {
          continue;
        }
        final existingCustomId = (data['customId'] as String? ?? '').trim().toUpperCase();
        if (existingCustomId == normalizedCustomId) {
          return false;
        }
      }
      return true;
    } catch (e) {
      throw 'Failed to validate custom ID: $e';
    }
  }

  /// Validate whether an email is unique within a company.
  Future<bool> isEmailAvailable({
    required String companyId,
    required String email,
    String? excludeUserId,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail.isEmpty) return false;

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('companyId', isEqualTo: companyId)
          .get();

      for (final doc in snapshot.docs) {
        if (excludeUserId != null && doc.id == excludeUserId) {
          continue;
        }
        final data = doc.data();
        final existingEmail = (data['email'] as String? ?? '').trim().toLowerCase();
        if (existingEmail == normalizedEmail) {
          return false;
        }
      }
      return true;
    } catch (e) {
      throw 'Failed to validate email: $e';
    }
  }

  /// Resolve supervisor / company admin login identifier to the Firebase Auth email.
  /// Accepts a normal email, a custom ID only (after company code step), or CompanyCode-CustomID.
  Future<String> resolveSupervisorOrAdminLoginEmail({
    required String companyId,
    required String companyCode,
    required String identifier,
  }) async {
    try {
      final trimmed = identifier.trim();
      if (trimmed.isEmpty) {
        throw 'Please enter your email or supervisor ID';
      }
      if (trimmed.contains('@')) {
        return trimmed;
      }

      final up = trimmed.toUpperCase();
      final code = companyCode.trim().toUpperCase();
      if (code.isEmpty) {
        throw 'Company code missing';
      }

      String customSlug;
      if (up == code) {
        throw 'Enter your supervisor ID (e.g. SUP001) or full CompanyCode-ID, not the company code alone';
      } else if (up.startsWith('$code-')) {
        customSlug = up.substring(code.length + 1).trim();
      } else {
        customSlug = up;
      }
      if (customSlug.isEmpty) {
        throw 'Invalid supervisor ID';
      }

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('companyId', isEqualTo: companyId)
          .get();

      final prefixed = '$code-$customSlug';
      final candidates = snapshot.docs.where((doc) {
        final data = doc.data();
        final role = data['role'] as String?;
        if (role != AppConstants.roleSupervisor &&
            role != 'companyadmin' &&
            role != AppConstants.roleAdmin) {
          return false;
        }
        final customId = (data['customId'] as String? ?? '').trim().toUpperCase();
        final employeeId = (data['employeeId'] as String? ?? '').trim().toUpperCase();
        return customId == customSlug ||
            employeeId == up ||
            employeeId == prefixed;
      }).toList();

      if (candidates.isEmpty) {
        throw 'No supervisor or admin account found for that ID in this company';
      }
      if (candidates.length > 1) {
        throw 'Multiple accounts matched. Please sign in with your email';
      }

      final email = candidates.first.data()['email'] as String? ?? '';
      final normalizedEmail = email.trim();
      if (normalizedEmail.isEmpty) {
        throw 'Account has no email on file';
      }
      return normalizedEmail;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to resolve login: $e';
    }
  }

  // ============================================
  // PROJECT OPERATIONS
  // ============================================

  /// Create new project
  Future<void> createProject(ProjectModel project) async {
    try {
      await _firestore
          .collection(AppConstants.projectsCollection)
          .doc(project.projectId)
          .set(project.toMap());
    } catch (e) {
      throw 'Failed to create project: $e';
    }
  }

  /// Get project by ID
  Future<ProjectModel?> getProject(String projectId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.projectsCollection)
          .doc(projectId)
          .get();

      if (!doc.exists) return null;

      return ProjectModel.fromMap(doc.data()!);
    } catch (e) {
      throw 'Failed to get project: $e';
    }
  }

  /// Get all active projects (filtered by company for multi-tenancy)
  Future<List<ProjectModel>> getActiveProjects() async {
    try {
      // Get current user's companyId for filtering
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      final role = userData['role'] as String?;
      final companyId = userData['companyId'] as String?;
      
      // Super admin sees all projects
      if (role == 'superadmin') {
        final snapshot = await _firestore
            .collection(AppConstants.projectsCollection)
            .where('isActive', isEqualTo: true)
            .get();
        return snapshot.docs.map((doc) => ProjectModel.fromMap(doc.data())).toList();
      }
      
      // Company admin/supervisor see only their company's projects
      if (companyId == null) {
        print('⚠️ Warning: User has no companyId, returning empty projects list');
        return [];
      }
      
      print('✅ Fetching active projects for company: $companyId');
      final snapshot = await _firestore
          .collection(AppConstants.projectsCollection)
          .where('companyId', isEqualTo: companyId)
          .where('isActive', isEqualTo: true)
          .get();

      print('✅ Found ${snapshot.docs.length} active projects for company');
      return snapshot.docs.map((doc) => ProjectModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw 'Failed to get active projects: $e';
    }
  }

  /// Get all projects (active and inactive, filtered by company for multi-tenancy)
  Future<List<ProjectModel>> getAllProjects() async {
    try {
      // Get current user's companyId for filtering
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      final role = userData['role'] as String?;
      final companyId = userData['companyId'] as String?;
      
      // Super admin sees all projects
      if (role == 'superadmin') {
        final snapshot = await _firestore
            .collection(AppConstants.projectsCollection)
            .get();
        return snapshot.docs.map((doc) => ProjectModel.fromMap(doc.data())).toList();
      }
      
      // Company admin/supervisor see only their company's projects
      if (companyId == null) {
        print('⚠️ Warning: User has no companyId, returning empty projects list');
        return [];
      }
      
      print('✅ Fetching all projects for company: $companyId');
      final snapshot = await _firestore
          .collection(AppConstants.projectsCollection)
          .where('companyId', isEqualTo: companyId)
          .get();

      print('✅ Found ${snapshot.docs.length} total projects for company');
      return snapshot.docs.map((doc) => ProjectModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw 'Failed to get all projects: $e';
    }
  }

  /// Create project from map (for web admin) - automatically adds companyId
  Future<void> createProjectFromMap(Map<String, dynamic> projectData) async {
    try {
      // Generate a unique project ID
      final projectId = _firestore.collection(AppConstants.projectsCollection).doc().id;
      projectData['projectId'] = projectId;
      
      // ✅ CRITICAL: Add companyId from current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final role = userData['role'] as String?;
          final companyId = userData['companyId'] as String?;
          
          // Super admin must specify companyId manually
          if (role == 'superadmin' && !projectData.containsKey('companyId')) {
            throw 'Super admin must specify companyId when creating projects';
          }
          
          // Company admin/supervisor: auto-add their companyId
          if (role != 'superadmin') {
            if (companyId == null) {
              throw 'User has no companyId - cannot create project';
            }
            projectData['companyId'] = companyId;
            print('✅ Auto-added companyId: $companyId to project');
          }
        }
      }

      await _firestore
          .collection(AppConstants.projectsCollection)
          .doc(projectId)
          .set(projectData);
          
      print('✅ Project created successfully: $projectId');
    } catch (e) {
      throw 'Failed to create project: $e';
    }
  }

  /// Update project
  Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(AppConstants.projectsCollection)
          .doc(projectId)
          .update(updates);
    } catch (e) {
      throw 'Failed to update project: $e';
    }
  }

  /// Get projects assigned to employee
  /// Uses assignment-based lookup to support legacy/new companyId formats.
  Future<List<ProjectModel>> getEmployeeProjects(String employeeId) async {
    try {
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔍 GET EMPLOYEE PROJECTS - START');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('Employee ID: $employeeId');
      
      // Get employee record (for assignedProjectId fallback)
      final employeeDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(employeeId)
          .get();
      
      if (!employeeDoc.exists) {
        print('❌ Employee not found: $employeeId');
        return [];
      }
      
      final employeeData = employeeDoc.data()!;

      // Match projects by any id shape stored in assignedEmployeeIds (uid, employeeId, etc.).
      // Query arrayContains + isActive requires a composite index — filter isActive in memory instead.
      final idKeys = <String>{employeeId.trim()};
      final eid = (employeeData['employeeId'] as String?)?.trim();
      if (eid != null && eid.isNotEmpty) {
        idKeys.add(eid);
        idKeys.add(eid.toUpperCase());
      }
      final cid = (employeeData['customId'] as String?)?.trim();
      if (cid != null && cid.isNotEmpty) {
        idKeys.add(cid);
        idKeys.add(cid.toUpperCase());
      }
      final sid = (employeeData['systemGeneratedId'] as String?)?.trim();
      if (sid != null && sid.isNotEmpty) {
        idKeys.add(sid);
        idKeys.add(sid.toUpperCase());
      }

      print('🔍 Fetching projects assigned to employee (keys: ${idKeys.length})');
      final seenProjectIds = <String>{};
      final assignedProjects = <ProjectModel>[];

      for (final key in idKeys) {
        if (key.isEmpty) continue;
        try {
          final snap = await _firestore
              .collection(AppConstants.projectsCollection)
              .where('assignedEmployeeIds', arrayContains: key)
              .get();
          for (final doc in snap.docs) {
            final p = ProjectModel.fromMap(doc.data());
            if (!p.isActive) continue;
            if (seenProjectIds.add(p.projectId)) {
              assignedProjects.add(p);
              print('   ✅ ${p.name}: matched via assignedEmployeeIds ($key)');
            }
          }
        } catch (e) {
          print('   ⚠️ assignedEmployeeIds query failed for key "$key": $e');
        }
      }

      // Fallback: if no projects from assignedEmployeeIds but user has legacy/new direct assignment
      // (e.g. assigned via Add Employee before fix), fetch that project and backfill the array
      if (assignedProjects.isEmpty) {
        final fallbackProjectIds = <String>{
          ...List<String>.from(employeeData['assignedProjectIds'] as List? ?? []),
        };
        final assignedProjectId = employeeData['assignedProjectId'] as String?;
        if (assignedProjectId != null && assignedProjectId.isNotEmpty) {
          fallbackProjectIds.add(assignedProjectId);
        }

        for (final fallbackId in fallbackProjectIds) {
          print('   🔄 Fallback: checking assigned project: $fallbackId');
          final project = await getProject(fallbackId);
          if (project != null && project.isActive) {
            if (seenProjectIds.add(project.projectId)) {
              assignedProjects.add(project);
            }
            print('   ✅ Added project from fallback assignment: ${project.name}');
            try {
              await _firestore
                  .collection(AppConstants.projectsCollection)
                  .doc(fallbackId)
                  .update({
                'assignedEmployeeIds': FieldValue.arrayUnion([employeeId]),
                'updatedAt': DateTime.now().toIso8601String(),
              });
            } catch (e) {
              print('   ⚠️ Backfill failed (non-blocking): $e');
            }
          }
        }
      }

      print('');
      print('📊 RESULT: Found ${assignedProjects.length} assigned projects');
      if (assignedProjects.isEmpty) {
        print('   ⚠️ No projects assigned to this employee!');
        print('   💡 Admin needs to assign employee to projects from web dashboard');
      } else {
        for (var project in assignedProjects) {
          print('   - ${project.name} (${project.projectId})');
        }
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔍 GET EMPLOYEE PROJECTS - END');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');

      return assignedProjects;
    } catch (e) {
      print('❌ ERROR in getEmployeeProjects: $e');
      throw 'Failed to get employee projects: $e';
    }
  }

  /// Assign employee to project
  /// Updates: project's assignedEmployees subcollection, project's assignedEmployeeIds
  /// (used by mobile check-in), and user's assignedProjectIds (multi-project)
  Future<void> assignEmployeeToProject({
    required String projectId,
    required String employeeId,
    required String employeeName,
    required String assignedBy,
  }) async {
    try {
      // 1. Add employee to project's assignedEmployees subcollection
      await _firestore
          .collection(AppConstants.projectsCollection)
          .doc(projectId)
          .collection(AppConstants.assignedEmployeesSubcollection)
          .doc(employeeId)
          .set({
        'userId': employeeId,
        'name': employeeName,
        'assignedAt': DateTime.now().toIso8601String(),
        'assignedBy': assignedBy,
        'isActive': true,
      });

      // 2. Add to project's assignedEmployeeIds so mobile getEmployeeProjects() shows project (check-in)
      await _firestore
          .collection(AppConstants.projectsCollection)
          .doc(projectId)
          .update({
        'assignedEmployeeIds': FieldValue.arrayUnion([employeeId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 3. Update the user's multi-project assignments without overriding legacy primary project
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(employeeId)
          .update({
        'assignedProjectIds': FieldValue.arrayUnion([projectId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to assign employee to project: $e';
    }
  }

  /// Unassign employee from project
  /// Removes from project subcollection, project's assignedEmployeeIds, and user's assignedProjectIds
  Future<void> unassignEmployeeFromProject({
    required String projectId,
    required String employeeId,
  }) async {
    try {
      // 1. Remove from project's assignedEmployees subcollection
      await _firestore
          .collection(AppConstants.projectsCollection)
          .doc(projectId)
          .collection(AppConstants.assignedEmployeesSubcollection)
          .doc(employeeId)
          .delete();

      // 2. Remove from project's assignedEmployeeIds so mobile no longer shows project
      await _firestore
          .collection(AppConstants.projectsCollection)
          .doc(projectId)
          .update({
        'assignedEmployeeIds': FieldValue.arrayRemove([employeeId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 3. Remove from user's assigned project fields
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(employeeId)
          .update({
        'assignedProjectIds': FieldValue.arrayRemove([projectId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to unassign employee from project: $e';
    }
  }

  /// Add employee to a project's assignedEmployeeIds (used by Add Employee flow for check-in)
  Future<void> addEmployeeToProjectAssignedList(String projectId, String employeeId) async {
    try {
      await _firestore
          .collection(AppConstants.projectsCollection)
          .doc(projectId)
          .update({
        'assignedEmployeeIds': FieldValue.arrayUnion([employeeId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to add employee to project assigned list: $e';
    }
  }

  /// Remove employee from a project's assignedEmployeeIds
  Future<void> removeEmployeeFromProjectAssignedList(String projectId, String employeeId) async {
    try {
      await _firestore
          .collection(AppConstants.projectsCollection)
          .doc(projectId)
          .update({
        'assignedEmployeeIds': FieldValue.arrayRemove([employeeId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to remove employee from project assigned list: $e';
    }
  }

  // ============================================
  // ATTENDANCE OPERATIONS
  // ============================================

  /// Create attendance record (check-in)
  Future<void> createAttendance(AttendanceModel attendance) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(attendance.userId)
          .collection(AppConstants.attendanceSubcollection)
          .doc(attendance.attendanceId)
          .set(attendance.toMap());
    } catch (e) {
      throw 'Failed to create attendance: $e';
    }
  }

  /// Update attendance (check-out)
  Future<void> updateAttendance({
    required String userId,
    required String attendanceId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('💾 FIRESTORE: updateAttendance()');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('User ID: $userId');
      print('Attendance ID: $attendanceId');
      print('Updates: ${updates.keys.join(", ")}');
      if (updates.containsKey('status')) {
        print('   Status changing to: ${updates['status']}');
      }
      if (updates.containsKey('checkOutTime')) {
        print('   Check-out time: ${updates['checkOutTime']}');
      }
      
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.attendanceSubcollection)
          .doc(attendanceId)
          .update(updates);
      
      print('✅ Attendance record UPDATED in Firestore');
      print('   Path: users/$userId/attendance/$attendanceId');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
    } catch (e) {
      print('❌ Error updating attendance: $e');
      print('   User ID: $userId');
      print('   Attendance ID: $attendanceId');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      throw 'Failed to update attendance: $e';
    }
  }

  /// Get specific attendance record by ID
  Future<AttendanceModel?> getAttendanceById(String userId, String attendanceId) async {
    try {
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📄 FIRESTORE: getAttendanceById()');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('User ID: $userId');
      print('Attendance ID: $attendanceId');
      
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.attendanceSubcollection)
          .doc(attendanceId)
          .get();
      
      if (!doc.exists) {
        print('❌ Attendance document not found');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('');
        return null;
      }
      
      final data = doc.data();
      if (data == null) {
        print('❌ Attendance document exists but has no data');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('');
        return null;
      }
      
      print('✅ Attendance document found');
      print('   Check-in time: ${data['checkInTime']}');
      print('   Status: ${data['status']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      
      return AttendanceModel.fromMap(data);
    } catch (e) {
      print('❌ Error fetching attendance by ID: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      throw 'Failed to get attendance: $e';
    }
  }

  /// Get today's active attendance for employee
  Future<AttendanceModel?> getTodayActiveAttendance(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final startOfDayStr = startOfDay.toIso8601String();
      final endOfDayStr = endOfDay.toIso8601String();

      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔍 FIRESTORE: getTodayActiveAttendance()');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('User ID: $userId');
      print('Date range: $startOfDayStr to $endOfDayStr');
      print('Status filter: ${AppConstants.attendanceStatusCheckedIn}');
      print('Forcing SERVER fetch (bypassing cache)...');

      // SIMPLIFIED QUERY - No index required!
      // Only use checkInTime filter, then filter in memory for status and today
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.attendanceSubcollection)
          .where('checkInTime', isGreaterThanOrEqualTo: startOfDayStr)
          .where('checkInTime', isLessThanOrEqualTo: endOfDayStr)
          // Removed status filter to avoid index requirement
          .orderBy('checkInTime', descending: true)
          .get(const GetOptions(source: Source.server)); // Force server fetch

      print('📊 Query returned ${snapshot.docs.length} documents from SERVER');

      if (snapshot.docs.isEmpty) {
        print('📋 No attendance records found for today');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('');
        return null;
      }

      // Filter in memory for status = 'checked_in'
      print('🔍 Filtering ${snapshot.docs.length} records for status=checked_in...');
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        
        if (status == AppConstants.attendanceStatusCheckedIn) {
          final attendanceId = data['attendanceId'] as String?;
          final checkInTime = data['checkInTime'] as String?;
          final checkInMethod = data['checkInMethod'] as String?;
          
          print('✅ Found active attendance (checked_in):');
          print('   Attendance ID: $attendanceId');
          print('   Check-in Time: $checkInTime');
          print('   Check-in Method: $checkInMethod');
          print('   Status: $status');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('');
          
          return AttendanceModel.fromMap(data);
        } else {
          print('   Skipping record with status: $status');
        }
      }
      
      print('📋 No checked-in attendance found (all records have different status)');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      return null;
      
    } catch (e, stackTrace) {
      print('❌ Error fetching today active attendance: $e');
      print('   Stack trace: $stackTrace');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      throw 'Failed to get today\'s attendance: $e';
    }
  }

  /// Get attendance history for employee
  Future<List<AttendanceModel>> getAttendanceHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.attendanceSubcollection)
          .orderBy('checkInTime', descending: true);

      if (startDate != null) {
        query = query.where('checkInTime', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('checkInTime', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      throw 'Failed to get attendance history: $e';
    }
  }

  /// Get attendance by date range (for reports)
  Future<List<AttendanceModel>> getAttendanceByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allAttendance = <AttendanceModel>[];
      
      // Get all employees
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleEmployee)
          .get();

      // For each employee, get their attendance in date range
      for (final userDoc in usersSnapshot.docs) {
        final attendanceSnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userDoc.id)
            .collection(AppConstants.attendanceSubcollection)
            .where('checkInTime',
                isGreaterThanOrEqualTo: startDate.toIso8601String())
            .where('checkInTime',
                isLessThanOrEqualTo: endDate.toIso8601String())
            .get();

        for (final doc in attendanceSnapshot.docs) {
          allAttendance.add(AttendanceModel.fromMap(doc.data()));
        }
      }

      // Sort by check-in time (most recent first)
      allAttendance.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

      return allAttendance;
    } catch (e) {
      throw 'Failed to get attendance by date range: $e';
    }
  }

  /// Get attendance by project (for reports)
  Future<List<AttendanceModel>> getAttendanceByProject(String projectId) async {
    try {
      final allAttendance = <AttendanceModel>[];
      
      // Get all employees
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleEmployee)
          .get();

      // For each employee, get their attendance for this project
      for (final userDoc in usersSnapshot.docs) {
        final attendanceSnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userDoc.id)
            .collection(AppConstants.attendanceSubcollection)
            .where('projectId', isEqualTo: projectId)
            .get();

        for (final doc in attendanceSnapshot.docs) {
          allAttendance.add(AttendanceModel.fromMap(doc.data()));
        }
      }

      return allAttendance;
    } catch (e) {
      throw 'Failed to get attendance by project: $e';
    }
  }

  /// Get attendance by user (for reports)
  Future<List<AttendanceModel>> getAttendanceByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.attendanceSubcollection)
          .orderBy('checkInTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw 'Failed to get attendance by user: $e';
    }
  }

  /// Get today's check-in count for project
  Future<int> getTodayCheckInCount({
    required String userId,
    required String projectId,
  }) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.attendanceSubcollection)
          .where('projectId', isEqualTo: projectId)
          .where('checkInTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ============================================
  // DOCUMENT OPERATIONS
  // ============================================

  /// Upload document metadata
  Future<void> createDocument(DocumentModel document) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(document.userId)
          .collection(AppConstants.documentsSubcollection)
          .doc(document.documentId)
          .set(document.toMap());
    } catch (e) {
      throw 'Failed to create document: $e';
    }
  }

  /// Get employee documents
  Future<List<DocumentModel>> getEmployeeDocuments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.documentsSubcollection)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => DocumentModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw 'Failed to get documents: $e';
    }
  }

  /// Get all documents for a specific company (for company admin view)
  /// Only fetches documents belonging to employees of the given company.
  /// If companyId is null (super admin), fetches all documents across all companies.
  Future<List<DocumentModel>> getAllDocuments({String? companyId}) async {
    try {
      final allDocuments = <DocumentModel>[];
      
      // Build query - filter by company if companyId provided
      Query<Map<String, dynamic>> query = _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleEmployee);
      
      if (companyId != null) {
        query = query.where('companyId', isEqualTo: companyId);
      }
      
      final usersSnapshot = await query.get();

      // For each user, get their documents
      for (final userDoc in usersSnapshot.docs) {
        final documentsSnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userDoc.id)
            .collection(AppConstants.documentsSubcollection)
            .get();

        for (final docSnapshot in documentsSnapshot.docs) {
          allDocuments.add(DocumentModel.fromMap(docSnapshot.data()));
        }
      }

      // Sort by upload date (most recent first)
      allDocuments.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return allDocuments;
    } catch (e) {
      throw 'Failed to get all documents: $e';
    }
  }

  /// Get documents for employees assigned to a specific supervisor.
  /// Only returns documents belonging to employees whose supervisorId matches.
  Future<List<DocumentModel>> getSupervisorEmployeeDocuments(String supervisorId) async {
    try {
      final allDocuments = <DocumentModel>[];
      
      // Get only employees assigned to this supervisor
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleEmployee)
          .where('supervisorId', isEqualTo: supervisorId)
          .get();

      for (final userDoc in usersSnapshot.docs) {
        final documentsSnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userDoc.id)
            .collection(AppConstants.documentsSubcollection)
            .orderBy('uploadedAt', descending: true)
            .get();

        for (final docSnapshot in documentsSnapshot.docs) {
          allDocuments.add(DocumentModel.fromMap(docSnapshot.data()));
        }
      }

      // Sort by upload date (most recent first)
      allDocuments.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return allDocuments;
    } catch (e) {
      throw 'Failed to get supervisor employee documents: $e';
    }
  }

  /// Update document (for approval/rejection)
  Future<void> updateDocument(
    String userId,
    String documentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.documentsSubcollection)
          .doc(documentId)
          .update(updates);
    } catch (e) {
      throw 'Failed to update document: $e';
    }
  }

  /// Delete document
  Future<void> deleteDocument({
    required String userId,
    required String documentId,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.documentsSubcollection)
          .doc(documentId)
          .delete();
    } catch (e) {
      throw 'Failed to delete document: $e';
    }
  }

  // ============================================
  // DEVICE RESET REQUEST OPERATIONS
  // ============================================

  /// Create device reset request
  Future<void> createDeviceResetRequest(DeviceResetRequestModel request) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(request.userId)
          .collection(AppConstants.deviceResetRequestsSubcollection)
          .doc(request.requestId)
          .set(request.toMap());
    } catch (e) {
      throw 'Failed to create device reset request: $e';
    }
  }

  /// Get pending device reset requests
  Future<List<DeviceResetRequestModel>> getPendingDeviceResetRequests() async {
    try {
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();

      final allRequests = <DeviceResetRequestModel>[];

      for (final userDoc in usersSnapshot.docs) {
        final requestsSnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userDoc.id)
            .collection(AppConstants.deviceResetRequestsSubcollection)
            .where('status', isEqualTo: AppConstants.statusPending)
            .get();

        for (final requestDoc in requestsSnapshot.docs) {
          allRequests.add(DeviceResetRequestModel.fromMap(requestDoc.data()));
        }
      }

      return allRequests;
    } catch (e) {
      throw 'Failed to get device reset requests: $e';
    }
  }

  /// Update device reset request
  Future<void> updateDeviceResetRequest({
    required String userId,
    required String requestId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.deviceResetRequestsSubcollection)
          .doc(requestId)
          .update(updates);
    } catch (e) {
      throw 'Failed to update device reset request: $e';
    }
  }

  /// Get device reset requests for a specific user
  Future<List<DeviceResetRequestModel>> getUserDeviceResetRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.deviceResetRequestsSubcollection)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DeviceResetRequestModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw 'Failed to get user device reset requests: $e';
    }
  }

  /// Get all device reset requests (for admin/supervisor)
  Future<List<DeviceResetRequestModel>> getAllDeviceResetRequests() async {
    try {
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();

      final allRequests = <DeviceResetRequestModel>[];

      for (final userDoc in usersSnapshot.docs) {
        final requestsSnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userDoc.id)
            .collection(AppConstants.deviceResetRequestsSubcollection)
            .orderBy('requestedAt', descending: true)
            .get();

        for (final requestDoc in requestsSnapshot.docs) {
          allRequests.add(DeviceResetRequestModel.fromMap(requestDoc.data()));
        }
      }

      return allRequests;
    } catch (e) {
      throw 'Failed to get all device reset requests: $e';
    }
  }

  /// Check if user can request device reset (based on monthly limit)
  Future<bool> canRequestDeviceReset(String userId, int monthlyLimit) async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.deviceResetRequestsSubcollection)
          .where('requestedAt', isGreaterThanOrEqualTo: firstDayOfMonth.toIso8601String())
          .where('status', whereIn: [AppConstants.statusPending, 'approved'])
          .get();

      return snapshot.docs.length < monthlyLimit;
    } catch (e) {
      throw 'Failed to check device reset eligibility: $e';
    }
  }

  /// Approve device reset request
  Future<void> approveDeviceResetRequest({
    required String userId,
    required String requestId,
    required String approvedBy,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.deviceResetRequestsSubcollection)
          .doc(requestId)
          .update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': DateTime.now().toIso8601String(),
      });

      // Clear device info from user profile
      await updateUser(userId, {
        'deviceInfo': null,
        'isDeviceRegistered': false,
      });
    } catch (e) {
      throw 'Failed to approve device reset request: $e';
    }
  }

  /// Reject device reset request
  Future<void> rejectDeviceResetRequest({
    required String userId,
    required String requestId,
    required String rejectedBy,
    String? rejectionReason,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.deviceResetRequestsSubcollection)
          .doc(requestId)
          .update({
        'status': 'rejected',
        'rejectedBy': rejectedBy,
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectionReason': rejectionReason,
      });
    } catch (e) {
      throw 'Failed to reject device reset request: $e';
    }
  }

  // ============================================
  // AUDIT LOG OPERATIONS
  // ============================================

  /// Create audit log
  Future<void> createAuditLog(AuditLogModel log) async {
    try {
      await _firestore
          .collection(AppConstants.auditLogsCollection)
          .doc(log.logId)
          .set(log.toMap());
    } catch (e) {
      // Don't throw error for audit logs to avoid breaking main operations
      print('Failed to create audit log: $e');
    }
  }

  /// Get audit logs
  Future<List<AuditLogModel>> getAuditLogs({
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.auditLogsCollection)
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) => AuditLogModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      throw 'Failed to get audit logs: $e';
    }
  }

  /// Get audit logs as stream
  Stream<List<AuditLogModel>> getAuditLogsStream({int limit = 50}) {
    return _firestore
        .collection(AppConstants.auditLogsCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditLogModel.fromMap(doc.data()))
            .toList());
  }

  // ============================================
  // SYSTEM SETTINGS OPERATIONS
  // ============================================

  /// Get system settings
  Future<Map<String, dynamic>?> getSystemSettings() async {
    try {
      final doc = await _firestore
          .collection(AppConstants.systemSettingsCollection)
          .doc('global')
          .get();

      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Update system settings
  Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      settings['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore
          .collection(AppConstants.systemSettingsCollection)
          .doc('global')
          .set(settings, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update system settings: $e';
    }
  }

  /// Get next employee ID counter (atomic, globally unique)
  Future<int> getNextEmployeeIdCounter() async {
    try {
      return await _firestore.runTransaction<int>((transaction) async {
        final docRef = _firestore
            .collection(AppConstants.systemSettingsCollection)
            .doc('global');

        final doc = await transaction.get(docRef);
        final counter = doc.data()?['employeeIdCounter'] as int? ?? 0;
        final nextCounter = counter + 1;

        transaction.set(docRef, {
          'employeeIdCounter': nextCounter,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        return nextCounter;
      });
    } catch (e) {
      throw 'Failed to get employee ID counter: $e';
    }
  }

  // ============================================
  // UTILITY OPERATIONS
  // ============================================

  /// Check if document exists
  Future<bool> documentExists(String collection, String docId) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Batch write operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final docRef = _firestore.collection(operation['collection']).doc(operation['docId']);
        
        switch (operation['type']) {
          case 'set':
            batch.set(docRef, operation['data']);
            break;
          case 'update':
            batch.update(docRef, operation['data']);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      throw 'Failed to perform batch write: $e';
    }
  }
}



