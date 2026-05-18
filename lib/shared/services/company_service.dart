import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_model.dart';
import 'firestore_service.dart';

/// Service for managing companies in multi-tenant system
class CompanyService {
  final FirebaseFirestore _firestore;

  CompanyService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _companiesCollection =>
      _firestore.collection('companies');

  bool _isPendingDeletion(Map<String, dynamic> data) {
    return (data['status'] as String?) == 'pendingDeletion';
  }

  // ============================================
  // CREATE
  // ============================================

  /// Create a new company
  Future<String> createCompany({
    required String name,
    required String companyCode,
    required String superAdminUid,
    String? logoUrl,
    bool allowSuperAdminView = true,
    required CompanyContact primaryContact,
    CompanySettings? settings,
    CompanySubscription? subscription,
  }) async {
    // Validate company code is unique
    final exists = await isCompanyCodeTaken(companyCode);
    if (exists) {
      throw Exception('Company code "$companyCode" is already taken');
    }

    // Validate company code format (3-6 uppercase letters)
    if (!RegExp(r'^[A-Z]{3,6}$').hasMatch(companyCode)) {
      throw Exception(
          'Company code must be 3-6 uppercase letters (e.g., ABC, XYZ)');
    }

    final now = DateTime.now();
    // ✅ Use company code as document ID (e.g., "ABC", "XYZ")
    final docRef = _companiesCollection.doc(companyCode.toUpperCase());

    final company = CompanyModel(
      id: companyCode.toUpperCase(),  // ✅ Company ID is same as company code
      name: name,
      companyCode: companyCode.toUpperCase(),
      logo: logoUrl,
      status: 'active',
      allowSuperAdminView: allowSuperAdminView,
      primaryContact: primaryContact,
      settings: settings ??
          CompanySettings(
            employeeIdPrefix: companyCode.toUpperCase(),
            employeeIdCounter: 0,
            workingHours: const WorkingHours(),
          ),
      subscription: subscription ?? const CompanySubscription(),
      createdBy: superAdminUid,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(company.toMap());
    return companyCode.toUpperCase();  // ✅ Return company code as ID
  }

  // ============================================
  // READ
  // ============================================

  /// Get company by ID
  /// This method handles both old random IDs and new company code IDs
  Future<CompanyModel?> getCompany(String companyId) async {
    try {
      print('🔍 Getting company by ID: $companyId');
      
      // First, try to get by document ID directly
      final doc = await _companiesCollection.doc(companyId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (_isPendingDeletion(data)) {
          print('⚠️ Company is pending deletion: $companyId');
          return null;
        }
        print('✅ Found company by ID: $companyId');
        return CompanyModel.fromMap(data);
      }
      
      // If not found by ID, try to find by company code
      // (for backwards compatibility with old random IDs)
      print('⚠️ Company not found by ID, trying by company code...');
      final querySnapshot = await _companiesCollection
          .where('companyCode', isEqualTo: companyId.toUpperCase())
          .get();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (_isPendingDeletion(data)) {
          continue;
        }

        print('✅ Found company by code: $companyId');
        return CompanyModel.fromMap(data);
      }
      
      print('❌ Company not found: $companyId');
      return null;
    } catch (e) {
      print('❌ Error fetching company: $e');
      return null;
    }
  }

  /// Get company by company code
  Future<CompanyModel?> getCompanyByCode(String companyCode) async {
    try {
      final querySnapshot = await _companiesCollection
          .where('companyCode', isEqualTo: companyCode.toUpperCase())
          .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (_isPendingDeletion(data)) {
          continue;
        }

        return CompanyModel.fromMap(data);
      }

      return null;
    } catch (e) {
      print('Error fetching company by code: $e');
      return null;
    }
  }

  /// Check if company code is already taken
  Future<bool> isCompanyCodeTaken(String companyCode) async {
    try {
      final company = await getCompanyByCode(companyCode);
      return company != null;
    } catch (e) {
      print('Error checking company code: $e');
      return false;
    }
  }

  /// Get all companies (for super admin)
  Future<List<CompanyModel>> getAllCompanies() async {
    try {
      final querySnapshot = await _companiesCollection
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((data) => !_isPendingDeletion(data))
          .map(CompanyModel.fromMap)
          .toList();
    } catch (e) {
      print('Error fetching all companies: $e');
      return [];
    }
  }

  /// Get active companies only
  Future<List<CompanyModel>> getActiveCompanies() async {
    try {
      final querySnapshot = await _companiesCollection
          .where('status', isEqualTo: 'active')
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) =>
              CompanyModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching active companies: $e');
      return [];
    }
  }

  /// Stream company data
  Stream<CompanyModel?> streamCompany(String companyId) {
    return _companiesCollection.doc(companyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CompanyModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  /// Stream all companies (for super admin dashboard)
  Stream<List<CompanyModel>> streamAllCompanies() {
    return _companiesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((data) => !_isPendingDeletion(data))
        .map(CompanyModel.fromMap)
        .toList());
  }

  // ============================================
  // UPDATE
  // ============================================

  /// Update company
  Future<void> updateCompany(String companyId,
      Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _companiesCollection.doc(companyId).update(updates);
    } catch (e) {
      print('Error updating company: $e');
      rethrow;
    }
  }

  /// Update company name
  Future<void> updateCompanyName(String companyId, String newName) async {
    await updateCompany(companyId, {'name': newName});
  }

  /// Update company logo
  Future<void> updateCompanyLogo(String companyId, String logoUrl) async {
    await updateCompany(companyId, {'logo': logoUrl});
  }

  /// Update company status
  Future<void> updateCompanyStatus(String companyId, String status) async {
    if (!['active', 'suspended', 'inactive'].contains(status)) {
      throw Exception('Invalid status: $status');
    }
    await updateCompany(companyId, {'status': status});
  }

  /// Suspend company
  Future<void> suspendCompany(String companyId) async {
    await updateCompanyStatus(companyId, 'suspended');
  }

  /// Activate company
  Future<void> activateCompany(String companyId) async {
    await updateCompanyStatus(companyId, 'active');
  }

  /// Update company settings
  Future<void> updateCompanySettings(
      String companyId, CompanySettings settings) async {
    await updateCompany(companyId, {'settings': settings.toMap()});
  }

  /// Increment employee ID counter and return next ID
  Future<String> getNextEmployeeId(String companyId) async {
    final company = await getCompany(companyId);
    if (company == null) {
      throw Exception('Company not found');
    }

    final prefix = company.settings.employeeIdPrefix;
    var nextNumber = company.settings.employeeIdCounter + 1;
    String employeeId;

    // Ensure generated full Employee ID is not already used.
    // This protects against legacy/manual duplicate data.
    while (true) {
      final paddedNumber = nextNumber.toString().padLeft(4, '0');
      employeeId = '$prefix-$paddedNumber';

      final exists = await _firestore
          .collection('users')
          .where('employeeId', isEqualTo: employeeId)
          .limit(1)
          .get();

      if (exists.docs.isEmpty) {
        break;
      }

      nextNumber++;
    }

    // Update per-company counter in Firestore to reserved number
    await _companiesCollection.doc(companyId).update({
      'settings.employeeIdCounter': nextNumber,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Get global sequential System ID
    final globalCounter = await FirestoreService().getNextEmployeeIdCounter();
    final systemId = globalCounter.toString().padLeft(4, '0');

    return '$employeeId|$systemId';
  }

  // ============================================
  // DELETE
  // ============================================

  /// Schedule company for deletion with a grace period (SA-8)
  /// Sets status to 'pendingDeletion' and stores the deletion date.
  /// If graceDays is 0, deletes immediately.
  Future<void> scheduleCompanyDeletion(String companyId, {int graceDays = 30}) async {
    try {
      if (graceDays <= 0) {
        // Immediate deletion
        await deleteCompanyPermanently(companyId);
      } else {
        final deletionDate = DateTime.now().add(Duration(days: graceDays));
        await updateCompany(companyId, {
          'status': 'pendingDeletion',
          'scheduledDeletionDate': deletionDate.toIso8601String(),
          'deletionGraceDays': graceDays,
        });
      }
    } catch (e) {
      print('Error scheduling company deletion: $e');
      rethrow;
    }
  }

  /// Cancel a scheduled deletion — restores company to 'suspended' status
  Future<void> cancelScheduledDeletion(String companyId) async {
    try {
      await updateCompany(companyId, {
        'status': 'suspended',
        'scheduledDeletionDate': null,
        'deletionGraceDays': null,
      });
    } catch (e) {
      print('Error cancelling deletion: $e');
      rethrow;
    }
  }

  /// Permanently delete company and all its data (super admin only)
  Future<void> deleteCompanyPermanently(String companyId) async {
    try {
      final companyDocIds = <String>{companyId};

      final legacyCompanySnapshot = await _companiesCollection
          .where('companyCode', isEqualTo: companyId.toUpperCase())
          .get();
      for (final doc in legacyCompanySnapshot.docs) {
        companyDocIds.add(doc.id);
      }

      // Delete all users belonging to this company
      final usersSnapshot = await _firestore
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in usersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete all projects belonging to this company
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('companyId', isEqualTo: companyId)
          .get();
      for (final doc in projectsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the company document itself
      for (final docId in companyDocIds) {
        batch.delete(_companiesCollection.doc(docId));
      }

      await batch.commit();
    } catch (e) {
      print('Error permanently deleting company: $e');
      rethrow;
    }
  }

  /// Legacy delete method
  Future<void> deleteCompany(String companyId) async {
    try {
      await _companiesCollection.doc(companyId).delete();
    } catch (e) {
      print('Error deleting company: $e');
      rethrow;
    }
  }

  // ============================================
  // STATISTICS
  // ============================================

  /// Get company statistics
  Future<Map<String, int>> getCompanyStats(String companyId) async {
    try {
      // Get counts from various collections
      final usersCount = await _firestore
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .count()
          .get();

      final projectsCount = await _firestore
          .collection('projects')
          .where('companyId', isEqualTo: companyId)
          .count()
          .get();

      final attendanceCount = await _firestore
          .collection('attendance')
          .where('companyId', isEqualTo: companyId)
          .count()
          .get();

      return {
        'users': usersCount.count ?? 0,
        'projects': projectsCount.count ?? 0,
        'attendance': attendanceCount.count ?? 0,
      };
    } catch (e) {
      print('Error fetching company stats: $e');
      return {'users': 0, 'projects': 0, 'attendance': 0};
    }
  }

  /// Get platform-wide statistics (super admin only)
  Future<Map<String, int>> getPlatformStats() async {
    try {
      final companiesCount = await _companiesCollection.count().get();

      final usersCount =
          await _firestore.collection('users').count().get();

      final projectsCount =
          await _firestore.collection('projects').count().get();

      final attendanceCount =
          await _firestore.collection('attendance').count().get();

      return {
        'companies': companiesCount.count ?? 0,
        'users': usersCount.count ?? 0,
        'projects': projectsCount.count ?? 0,
        'attendance': attendanceCount.count ?? 0,
      };
    } catch (e) {
      print('Error fetching platform stats: $e');
      return {
        'companies': 0,
        'users': 0,
        'projects': 0,
        'attendance': 0
      };
    }
  }

  // ============================================
  // VALIDATION
  // ============================================

  /// Validate company exists and is active
  Future<bool> isCompanyActive(String companyId) async {
    final company = await getCompany(companyId);
    return company?.isActive ?? false;
  }

  /// Get company by ID with validation
  Future<CompanyModel> getCompanyOrThrow(String companyId) async {
    final company = await getCompany(companyId);
    if (company == null) {
      throw Exception('Company not found: $companyId');
    }
    return company;
  }
}

