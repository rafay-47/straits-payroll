import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/document_model.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

// User Documents Stream Provider
final userDocumentsProvider = StreamProvider.autoDispose
    .family<List<DocumentModel>, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).streamUserDocuments(userId);
});

// Document Controller
class DocumentController extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final String userId;

  DocumentController(
    this._firestoreService,
    this._storageService,
    this.userId,
  ) : super(const AsyncValue.data(null));

  // Upload document
  Future<void> uploadDocument({
    required File file,
    required DocumentType type,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Check file size
      final isValidSize =
          await _storageService.isFileSizeValid(file, maxSizeMB: 10);
      if (!isValidSize) {
        throw Exception('File size exceeds 10 MB limit');
      }

      // Upload file to storage
      final fileUrl = await _storageService.uploadDocument(file, userId);

      // Get file size
      final fileSizeInMB = await _storageService.getFileSizeInMB(file);

      // Create document metadata
      final document = DocumentModel(
        id: '', // Will be set by Firestore
        userId: userId,
        fileName: file.path.split('/').last,
        fileUrl: fileUrl,
        type: type,
        fileSizeInMB: fileSizeInMB,
        uploadedAt: DateTime.now(),
        description: description,
      );

      // Save metadata to Firestore
      await _firestoreService.uploadDocumentMetadata(document);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Delete document
  Future<void> deleteDocument(DocumentModel document) async {
    state = const AsyncValue.loading();
    try {
      // Delete file from storage
      await _storageService.deleteFile(document.fileUrl);

      // Delete metadata from Firestore
      await _firestoreService.deleteDocument(userId, document.id); // Pass userId for subcollection path

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Document Controller Provider
final documentControllerProvider = StateNotifierProvider.autoDispose
    .family<DocumentController, AsyncValue<void>, String>((ref, userId) {
  return DocumentController(
    ref.watch(firestoreServiceProvider),
    ref.watch(storageServiceProvider),
    userId,
  );
});
