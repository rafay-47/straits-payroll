import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/document_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// ============================================
// SERVICE PROVIDER
// ============================================

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// ============================================
// DOCUMENT PROVIDERS (Real-time streams)
// ============================================

/// Employee documents provider - streams documents for a specific employee.
/// Access control: The calling screen must ensure the current user is authorized
/// to view this employee's documents (i.e., is the employee themselves,
/// their immediate supervisor, or a company admin in the same company).
final employeeDocumentsProvider =
    StreamProvider.family<List<DocumentModel>, String>((ref, userId) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  
  if (currentUser == null) {
    yield [];
    return;
  }
  
  try {
    // Enforce visibility: employee can only see their own docs
    if (currentUser.isEmployee && currentUser.uid != userId) {
      yield [];
      return;
    }
    
    // For supervisor/admin, verify access via user document
    if (currentUser.isSupervisor || currentUser.isCompanyAdmin) {
      final targetUser = await firestoreService.getUser(userId);
      if (targetUser == null) {
        yield [];
        return;
      }
      if (currentUser.isSupervisor &&
          targetUser.supervisorId != currentUser.uid) {
        yield [];
        return;
      }
      if (currentUser.isCompanyAdmin &&
          targetUser.companyId != currentUser.companyId) {
        yield [];
        return;
      }
    }
    
    // Stream the documents
    yield* firestoreService.streamDocumentsByUser(userId);
  } catch (e) {
    print('Error fetching documents stream: $e');
    yield [];
  }
});

/// Current user's own documents provider (real-time)
final currentUserDocumentsProvider = StreamProvider<List<DocumentModel>>((ref) async* {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    yield [];
    return;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    yield* firestoreService.streamDocumentsByUser(user.uid);
  } catch (e) {
    print('Error fetching current user documents stream: $e');
    yield [];
  }
});

/// Company-scoped documents provider (for company admin web view).
/// Real-time stream of documents for all employees within the admin's company.
final companyDocumentsProvider = StreamProvider<List<DocumentModel>>((ref) async* {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    yield [];
    return;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);

  try {
    if (currentUser.isSuperAdmin) {
      // Super admin: stream all employees and aggregate their documents
      yield* _streamAllCompanyDocuments(firestoreService, null);
    } else if (currentUser.isCompanyAdmin && currentUser.companyId != null) {
      yield* _streamAllCompanyDocuments(
        firestoreService,
        currentUser.companyId,
      );
    } else {
      // Other roles should not access this provider
      yield [];
    }
  } catch (e) {
    print('Error fetching company documents stream: $e');
    yield [];
  }
});

/// Helper: stream documents for all employees in a company
Stream<List<DocumentModel>> _streamAllCompanyDocuments(
  FirestoreService firestoreService,
  String? companyId,
) async* {
  // Stream company employees, then stream their documents
  Stream<List<UserModel>> employeeStream;
  if (companyId == null) {
    employeeStream = firestoreService.streamAllUsers();
  } else {
    employeeStream =
        firestoreService.streamAllUsersForCompany(companyId);
  }

  await for (final users in employeeStream) {
    // For each user snapshot, fetch their documents
    final allDocs = <DocumentModel>[];
    for (final user in users) {
      try {
        // One-shot fetch per employee (acceptable since this is a batch aggregation)
        final docs = await firestoreService.getEmployeeDocuments(user.uid);
        allDocs.addAll(docs);
      } catch (_) {}
    }
    allDocs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    yield allDocs;
  }
}

/// Supervisor documents provider (for supervisor mobile view).
/// Real-time stream of documents for employees assigned to this supervisor.
final supervisorDocumentsProvider =
    StreamProvider<List<DocumentModel>>((ref) async* {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null || !currentUser.isSupervisor) {
    yield [];
    return;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);

  try {
    // Stream the list of employees assigned to this supervisor
    await for (final employees
        in firestoreService.streamEmployeesBySupervisor(currentUser.uid)) {
      // Aggregate their documents
      final allDocs = <DocumentModel>[];
      for (final emp in employees) {
        try {
          final docs = await firestoreService.getEmployeeDocuments(emp.uid);
          allDocs.addAll(docs);
        } catch (_) {}
      }
      allDocs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      yield allDocs;
    }
  } catch (e) {
    print('Error fetching supervisor documents stream: $e');
    yield [];
  }
});

// ============================================
// DOCUMENT CONTROLLER
// ============================================

/// Document state
class DocumentState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final double uploadProgress;

  const DocumentState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.uploadProgress = 0.0,
  });

  DocumentState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    double? uploadProgress,
  }) {
    return DocumentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

/// Document controller
class DocumentController extends StateNotifier<DocumentState> {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final Ref _ref;

  DocumentController(
    this._firestoreService,
    this._storageService,
    this._ref,
  ) : super(const DocumentState());

  /// Upload document
  Future<bool> uploadDocument({
    required String userId,
    required File file,
    required String documentType,
    required String uploadedBy,
  }) async {
    state = state.copyWith(isLoading: true, error: null, uploadProgress: 0.0);

    try {
      // Validate file
      if (!_storageService.isValidDocumentFile(file)) {
        throw 'Invalid file. File size must be under 10MB and format must be jpg, png, pdf, doc, or docx';
      }

      // Get companyId from current user
      final currentUser = _ref.read(currentUserProvider).value;
      if (currentUser == null || currentUser.companyId == null) {
        throw 'User not found or company not set';
      }
      
      final companyId = currentUser.companyId!;

      // Upload file to Storage with company-scoped path
      final downloadUrl = await _storageService.uploadDocumentWithProgress(
        companyId: companyId,
        userId: userId,
        file: file,
        documentType: documentType,
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress);
        },
      );

      // Create document metadata in Firestore
      final document = DocumentModel(
        documentId: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        companyId: companyId,
        userId: userId,
        type: documentType,
        name: file.path.split('/').last,
        url: downloadUrl,
        fileSizeBytes: file.lengthSync(),
        mimeType: _getMimeType(file),
        uploadedBy: uploadedBy,
        uploadedAt: DateTime.now(),
      );

      await _firestoreService.createDocument(document);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Document uploaded successfully',
        uploadProgress: 1.0,
      );

      // Refresh documents list
      _ref.invalidate(employeeDocumentsProvider(userId));
      _ref.invalidate(currentUserDocumentsProvider);
      _ref.invalidate(companyDocumentsProvider);
      _ref.invalidate(supervisorDocumentsProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        uploadProgress: 0.0,
      );
      return false;
    }
  }

  /// Delete document
  Future<bool> deleteDocument({
    required String userId,
    required String documentId,
    required String fileUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Delete file from Storage
      await _storageService.deleteFile(fileUrl);

      // Delete document metadata from Firestore
      await _firestoreService.deleteDocument(
        userId: userId,
        documentId: documentId,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Document deleted successfully',
      );

      // Refresh documents list
      _ref.invalidate(employeeDocumentsProvider(userId));
      _ref.invalidate(currentUserDocumentsProvider);
      _ref.invalidate(companyDocumentsProvider);
      _ref.invalidate(supervisorDocumentsProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Get mime type from file
  String _getMimeType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

/// Document controller provider
final documentControllerProvider =
    StateNotifierProvider<DocumentController, DocumentState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return DocumentController(firestoreService, storageService, ref);
});

