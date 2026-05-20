import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/document_model.dart';
import 'auth_provider.dart';

// ============================================
// SERVICE PROVIDER
// ============================================

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// ============================================
// DOCUMENT PROVIDERS
// ============================================

/// Employee documents provider - fetches documents for a specific employee.
/// Access control: The calling screen must ensure the current user is authorized
/// to view this employee's documents (i.e., is the employee themselves,
/// their immediate supervisor, or a company admin in the same company).
final employeeDocumentsProvider = FutureProvider.family<List<DocumentModel>, String>(
  (ref, userId) async {
    final firestoreService = ref.watch(firestoreServiceProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    
    if (currentUser == null) return [];
    
    try {
      // Enforce visibility: employee can only see their own docs
      if (currentUser.isEmployee && currentUser.uid != userId) {
        return [];
      }
      
      // Supervisor can only see documents of their assigned employees
      if (currentUser.isSupervisor) {
        final targetUser = await firestoreService.getUser(userId);
        if (targetUser == null || targetUser.supervisorId != currentUser.uid) {
          return [];
        }
      }
      
      // Company admin can only see documents within their own company
      if (currentUser.isCompanyAdmin) {
        final targetUser = await firestoreService.getUser(userId);
        if (targetUser == null || targetUser.companyId != currentUser.companyId) {
          return [];
        }
      }
      
      return await firestoreService.getEmployeeDocuments(userId);
    } catch (e) {
      print('Error fetching documents: $e');
      return [];
    }
  },
);

/// Current user's own documents provider
final currentUserDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.asData?.value;
  if (user == null) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    return await firestoreService.getEmployeeDocuments(user.uid);
  } catch (e) {
    print('Error fetching current user documents: $e');
    return [];
  }
});

/// Company-scoped documents provider (for company admin web view).
/// Only returns documents for employees within the admin's company.
final companyDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);

  try {
    if (currentUser.isSuperAdmin) {
      // Super admin sees all documents across all companies
      return await firestoreService.getAllDocuments();
    } else if (currentUser.isCompanyAdmin) {
      // Company admin sees only their company's documents
      return await firestoreService.getAllDocuments(companyId: currentUser.companyId);
    } else {
      // Other roles should not access this provider
      return [];
    }
  } catch (e) {
    print('Error fetching company documents: $e');
    return [];
  }
});

/// Supervisor documents provider (for supervisor mobile view).
/// Only returns documents for employees assigned to this supervisor.
final supervisorDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null || !currentUser.isSupervisor) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);

  try {
    return await firestoreService.getSupervisorEmployeeDocuments(currentUser.uid);
  } catch (e) {
    print('Error fetching supervisor documents: $e');
    return [];
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

